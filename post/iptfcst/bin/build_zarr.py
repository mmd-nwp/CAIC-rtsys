import os
import glob
import argparse
import numpy as np
import xarray as xr
import pandas as pd
import pygrib
from datetime import datetime, timedelta

def convert_wrf_to_zarr(input_pattern, output_dir, model_id):
    """Processes WRF NetCDF files into Zarr with dynamic YYMMDDHH naming."""
    files = sorted(glob.glob(input_pattern))
    
    if not files:
        print(f"Error: No files found matching '{input_pattern}'")
        return

    print(f"Found {len(files)} WRF files. Stitching them together...")

    try:
        ds = xr.open_mfdataset(
            files, concat_dim='Time', combine='nested',
            parallel=False, coords='minimal', compat='override'
        )
    except Exception as e:
        print(f"Error opening datasets: {e}")
        return

    # ADDED 'CLDFRA' TO EXTRACT CLOUD DATA
    vars_to_keep = ['T2', 'U10', 'V10', 'RAINC', 'RAINNC', 'XLAT', 'XLONG', 'XTIME', 
                    'Q2', 'PSFC', 'HGT', 'SNOWNC', 'GRAUPELNC', 'UST', 'SINALPHA', 'COSALPHA', 'CLDFRA']
    
    vars_present = [v for v in vars_to_keep if v in ds.variables]
    ds_lean = ds[vars_present]

    # --- Extract Initialization Time for Filename ---
    ts_str = "unknown_time"
    if 'SIMULATION_START_DATE' in ds.attrs:
        init_str = ds.attrs['SIMULATION_START_DATE']
        ds_lean.attrs['init_time'] = init_str
        try:
            init_dt = datetime.strptime(init_str, '%Y-%m-%d_%H:%M:%S')
            ts_str = init_dt.strftime('%y%m%d%H')
        except Exception as e:
            print(f"Warning: Could not parse WRF init time: {e}")
    
    # --- 1. Temperature Conversion (K to F) ---
    if 'T2' in ds_lean:
        ds_lean['T2'] = (ds_lean['T2'] - 273.15) * 1.8 + 32

    # --- 2. Wind Processing (m/s to mph) ---
    if all(var in ds_lean for var in ['U10', 'V10', 'SINALPHA', 'COSALPHA']):
        print("Rotating WRF winds and converting to mph...")
        u_true = ds_lean['U10'] * ds_lean['COSALPHA'] - ds_lean['V10'] * ds_lean['SINALPHA']
        v_true = ds_lean['V10'] * ds_lean['COSALPHA'] + ds_lean['U10'] * ds_lean['SINALPHA']
        
        ds_lean['WIND_SPD'] = np.sqrt(u_true**2 + v_true**2) * 2.23694
        ds_lean['WIND_DIR'] = (np.degrees(np.arctan2(u_true, v_true)) + 180) % 360
        
        if 'UST' in ds_lean:
            ds_lean['WIND_GST'] = (np.sqrt(u_true**2 + v_true**2) + (7.71 * ds_lean['UST'])) * 2.23694

        ds_lean = ds_lean.drop_vars(['U10', 'V10', 'UST', 'SINALPHA', 'COSALPHA'])

    # --- 3. Precipitation Processing ---
    if 'RAINC' in ds_lean and 'RAINNC' in ds_lean:
        ds_lean['RAIN'] = (ds_lean['RAINC'] + ds_lean['RAINNC']) / 25.4
        ds_lean = ds_lean.drop_vars(['RAINC', 'RAINNC'])

    # --- 4. THE SNOW FIX: Incremental Density Processing ---
    if 'SNOWNC' in ds_lean and 'GRAUPELNC' in ds_lean:
        print("Calculating WRF Snow Depth based on incremental hourly density...")
        
        accum_swe_in = (ds_lean['SNOWNC'] + ds_lean['GRAUPELNC']) / 25.4
        hourly_swe = accum_swe_in.diff(dim='Time' if 'Time' in accum_swe_in.dims else 'time')
        
        first_hour_swe = accum_swe_in.isel(**{('Time' if 'Time' in accum_swe_in.dims else 'time'): slice(0, 1)})
        hourly_swe = xr.concat([first_hour_swe, hourly_swe], dim='Time' if 'Time' in accum_swe_in.dims else 'time')
        hourly_swe = xr.where(hourly_swe < 0, 0, hourly_swe)

        t_f = ds_lean['T2']
        density = xr.where(t_f <= 20, 15.0,
                    xr.where(t_f <= 32, 15.0 - 5.0 * ((t_f - 20.0) / 12.0),
                      xr.where(t_f <= 36, 10.0 - 9.0 * ((t_f - 32.0) / 4.0), 
                        0.0)))
        
        hourly_snow = hourly_swe * density
        ds_lean['SNOW'] = hourly_snow.cumsum(dim='Time' if 'Time' in hourly_snow.dims else 'time')
        ds_lean = ds_lean.drop_vars(['SNOWNC', 'GRAUPELNC'])

    # --- Make Elevation a Static 2D Array ---
    if 'HGT' in ds_lean and 'Time' in ds_lean['HGT'].dims:
        print("Extracting static 2D surface elevation...")
        ds_lean['HGT'] = ds_lean['HGT'].isel(Time=0, drop=True) * 3.28084

    # --- 5. Dew Point Processing ---
    if 'Q2' in ds_lean and 'PSFC' in ds_lean:
        q2_safe = ds_lean['Q2'].clip(min=1e-6)
        e = (q2_safe * ds_lean['PSFC']) / (0.622 + q2_safe)
        log_e = np.log(e / 611.2)
        td_c = (243.5 * log_e) / (17.67 - log_e)
        ds_lean['TD2'] = (td_c * 1.8) + 32
        ds_lean = ds_lean.drop_vars(['Q2', 'PSFC'])

    # --- 6. Cloud Cover Processing ---
    if 'CLDFRA' in ds_lean:
        print("Compressing 3D WRF Cloud Fractions to 2D Total Cloud Cover...")
        # Max cloud fraction in the column, multiplied by 100 to get a percentage
        if 'bottom_top' in ds_lean['CLDFRA'].dims:
            ds_lean['CLOUD'] = ds_lean['CLDFRA'].max(dim='bottom_top') * 100.0
        else:
            ds_lean['CLOUD'] = ds_lean['CLDFRA'] * 100.0
        ds_lean = ds_lean.drop_vars(['CLDFRA'])

    if 'Time' in ds_lean.dims:
        ds_lean = ds_lean.rename({'Time': 'time'})

    ds_chunked = ds_lean.chunk({'time': -1, 'south_north': 50, 'west_east': 50})

    os.makedirs(output_dir, exist_ok=True)
    final_output_path = os.path.join(output_dir, f"{model_id}_{ts_str}.zarr")

    print(f"Writing optimized WRF Zarr store to: {final_output_path}")
    try:
        ds_chunked.to_zarr(final_output_path, mode='w')
        print("SUCCESS: WRF Zarr conversion complete!")
    except Exception as e:
        print(f"Error writing to Zarr: {e}")

def convert_ncep_to_zarr(input_pattern, output_dir, model_id):
    """Processes NCEP GRIB2 files into an optimized Zarr store with standardized time mapping."""
    
    files = sorted(glob.glob(input_pattern))
    if not files:
        print(f"Error: No {model_id.upper()} files found matching '{input_pattern}'")
        return

    print(f"Found {len(files)} {model_id.upper()} file(s). Extracting data...")

    static_hgt = None
    if model_id in ['nbm', 'ndfd']:
        MASTER_HGT_FILE = f"/home/caic/caic/rtsys/post/iptfcst/terrain/{model_id}_terrain.grb2"
        if os.path.exists(MASTER_HGT_FILE):
            try:
                hgrbs = pygrib.open(MASTER_HGT_FILE)
                hmsg = hgrbs.select(parameterCategory=3, parameterNumber=5, level=0)[0]
                static_hgt = hmsg.values * 3.28084 
                hgrbs.close()
            except Exception as e:
                print(f"Warning: Could not read master elevation file: {e}")

    master_data = {}
    lats, lons = None, None
    init_dt = None

    for fpath in files:
        try:
            grbs = pygrib.open(fpath)
        except Exception as e:
            continue

        if init_dt is None:
            try:
                msg1 = grbs.message(1) 
                date_str = str(msg1.dataDate)
                time_str = f"{msg1.dataTime:04d}"
                init_dt = datetime.strptime(f"{date_str}{time_str}", "%Y%m%d%H%M")
            except:
                try: init_dt = grbs.message(1).analDate
                except: pass

        for msg in grbs:

            keys = msg.keys()
            if 'percentileValue' in keys or 'probabilityType' in keys:
                continue

            msg_str = str(msg).lower()
            if 'std dev' in msg_str or 'percentile' in msg_str or 'probability' in msg_str:
                continue
            
            if lats is None:
                try: lats, lons = msg.latlons()
                except: pass

            step_range = str(getattr(msg, 'stepRange', ''))

            try:
                if '-' in step_range:
                    end_fhr = int(step_range.split('-')[-1])
                    valid_time = init_dt + timedelta(hours=end_fhr)
                else:
                    valid_time = init_dt + timedelta(hours=int(step_range))
            except Exception as e:
                print(f"Time math failed for step_range '{step_range}': {e}")
                try: valid_time = msg.validDate
                except: continue

            # --- STANDARDIZED TIME EXTRACTION ---
            if init_dt is None:
                try:
                    date_str = str(msg.dataDate)
                    time_str = f"{msg.dataTime:04d}"
                    init_dt = datetime.strptime(f"{date_str}{time_str}", "%Y%m%d%H%M")
                except:
                    try: init_dt = msg.analDate
                    except: init_dt = valid_time 

            cat, num, level = getattr(msg, 'parameterCategory', None), getattr(msg, 'parameterNumber', None), getattr(msg, 'level', None)
            step_range, step_type = str(getattr(msg, 'stepRange', '')), getattr(msg, 'stepType', None)

            is_nbm_valid_accum = False
            if model_id == 'nbm' and step_type == 'accum' and '-' in step_range:
                try:
                    end_fhr = int(step_range.split('-')[-1])
                    expected_range = f"{end_fhr-1}-{end_fhr}" if end_fhr <= 36 else f"{end_fhr-6}-{end_fhr}"
                    if step_range == expected_range:
                        is_nbm_valid_accum = True
                except: pass

            target_var = None
            if cat == 0 and num == 0 and level == 2: target_var = 'T2'
            elif cat == 0 and num == 6 and level == 2: target_var = 'TD2'
            elif cat == 2 and num == 2 and level == 10: target_var = 'U10'
            elif cat == 2 and num == 3 and level == 10: target_var = 'V10'
            elif cat == 2 and num == 1 and level == 10: target_var = 'WIND_SPD'
            elif cat == 2 and num == 0 and level == 10: target_var = 'WIND_DIR'
            elif cat == 2 and num == 22: target_var = 'WIND_GST'
            
            # TOTAL CLOUD COVER (%)
            elif cat == 6 and num == 1: target_var = 'CLOUD'

            elif cat == 3 and num == 5 and level == 0:
                if static_hgt is None: static_hgt = msg.values * 3.28084
                continue 
                
            elif cat == 1 and num == 8 and step_type == 'accum':
                if model_id == 'nbm' and is_nbm_valid_accum:
                    target_var = 'RAIN'
                elif model_id == 'ndfd': target_var = 'RAIN'
                elif model_id == 'hrrr' and step_range.startswith('0-'): target_var = 'RAIN'
                    
            elif cat == 1 and num == 29 and step_type == 'accum':
                if model_id == 'nbm' and is_nbm_valid_accum:
                    target_var = 'SNOW'
                elif model_id == 'ndfd': target_var = 'SNOW'
                elif model_id == 'hrrr' and step_range.startswith('0-'): target_var = 'SNOW'

            if target_var:
                if valid_time not in master_data:
                    master_data[valid_time] = {}
                master_data[valid_time][target_var] = msg.values

        grbs.close()

    if init_dt is not None and init_dt not in master_data:
        master_data[init_dt] = {}

    if not master_data or lats is None:
        print("Error: Could not extract valid fields or grid coordinates from GRIB files.")
        return

    hourly_datasets = []
    
    for valid_time in sorted(master_data.keys()):
        data_vars = master_data[valid_time]

        if 'U10' in data_vars and 'V10' in data_vars:
            if 'WIND_SPD' not in data_vars: data_vars['WIND_SPD'] = np.sqrt(data_vars['U10']**2 + data_vars['V10']**2)
            if 'WIND_DIR' not in data_vars: data_vars['WIND_DIR'] = (np.degrees(np.arctan2(data_vars['U10'], data_vars['V10'])) + 180) % 360

        if 'T2' in data_vars:       data_vars['T2'] = (data_vars['T2'] - 273.15) * 1.8 + 32
        if 'TD2' in data_vars:      data_vars['TD2'] = (data_vars['TD2'] - 273.15) * 1.8 + 32
        if 'WIND_SPD' in data_vars: data_vars['WIND_SPD'] = data_vars['WIND_SPD'] * 2.23694
        if 'WIND_GST' in data_vars: data_vars['WIND_GST'] = data_vars['WIND_GST'] * 2.23694

        if 'RAIN' in data_vars:
            arr = data_vars['RAIN']
            if np.ma.isMaskedArray(arr): arr = arr.filled(0.0)
            data_vars['RAIN'] = np.nan_to_num(arr, nan=0.0) / 25.4
        if 'SNOW' in data_vars:
            arr = data_vars['SNOW']
            if np.ma.isMaskedArray(arr): arr = arr.filled(0.0)
            data_vars['SNOW'] = np.nan_to_num(arr, nan=0.0) * 39.3701

        for v in ['T2', 'TD2', 'WIND_SPD', 'WIND_DIR', 'WIND_GST', 'RAIN', 'SNOW', 'CLOUD']:
            if v not in data_vars:
                data_vars[v] = np.full(lats.shape, np.nan)

        ds_hour = xr.Dataset(
            {
                'T2': (['south_north', 'west_east'], data_vars['T2']),
                'TD2': (['south_north', 'west_east'], data_vars['TD2']),
                'WIND_SPD': (['south_north', 'west_east'], data_vars['WIND_SPD']),
                'WIND_DIR': (['south_north', 'west_east'], data_vars['WIND_DIR']),
                'WIND_GST': (['south_north', 'west_east'], data_vars['WIND_GST']),
                'RAIN': (['south_north', 'west_east'], data_vars['RAIN']),
                'SNOW': (['south_north', 'west_east'], data_vars['SNOW']),
                'CLOUD': (['south_north', 'west_east'], data_vars['CLOUD']),
            },
            coords={
                'time': [pd.to_datetime(valid_time)],
                'XLAT': (['south_north', 'west_east'], lats),
                'XLONG': (['south_north', 'west_east'], lons),
            }
        )
        hourly_datasets.append(ds_hour)

    print(f"Stitching {len(hourly_datasets)} datasets together...")
    ds_combined = xr.concat(hourly_datasets, dim='time')
    
    if model_id in ['nbm', 'ndfd']:
        print(f"Converting {model_id.upper()} incremental precipitation to storm totals...")
        
        if 'RAIN' in ds_combined:
            rain_mask = ds_combined['RAIN'].notnull()
            ds_combined['RAIN'] = ds_combined['RAIN'].fillna(0.0).cumsum(dim='time').where(rain_mask)
            
        if 'SNOW' in ds_combined:
            snow_mask = ds_combined['SNOW'].notnull()
            ds_combined['SNOW'] = ds_combined['SNOW'].fillna(0.0).cumsum(dim='time').where(snow_mask)
    
    if static_hgt is not None and static_hgt.shape == lats.shape:
        ds_combined['HGT'] = (['south_north', 'west_east'], static_hgt)

    if init_dt is not None:
        ds_combined.attrs['init_time'] = init_dt.strftime('%Y-%m-%d_%H:%M:%S')

    ds_chunked = ds_combined.chunk({'time': -1, 'south_north': 50, 'west_east': 50})
    ts_str = init_dt.strftime('%y%m%d%H') if init_dt else "unknown_time"
    os.makedirs(output_dir, exist_ok=True)
    final_output_path = os.path.join(output_dir, f"{model_id}_{ts_str}.zarr")

    ds_chunked.to_zarr(final_output_path, mode='w')
    print(f"SUCCESS: {model_id.upper()} Zarr conversion complete!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert WRF/NCEP files to an optimized Zarr store.")
    parser.add_argument('--input', type=str, required=True, help="File pattern")
    parser.add_argument('--output', type=str, required=True, help="Output directory")
    parser.add_argument('--model', type=str, default='wrf', help="Specify the model name")
    args = parser.parse_args()
    
    if args.model.lower().startswith('wrf'):
        convert_wrf_to_zarr(args.input, args.output, args.model)
    else:
        convert_ncep_to_zarr(args.input, args.output, args.model)
