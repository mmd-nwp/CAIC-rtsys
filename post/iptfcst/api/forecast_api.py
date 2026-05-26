from flask import Flask, request, jsonify
import xarray as xr
import pyproj
import numpy as np
import pandas as pd
import glob
import os
from scipy.ndimage import map_coordinates

app = Flask(__name__)

# Base directory where all the dynamic Zarr stores are kept
ZARR_BASE_DIR = '/data/iptfcst'

def get_latest_zarr_path(model_id):
    pattern = os.path.join(ZARR_BASE_DIR, f"{model_id}_*.zarr")
    files = sorted(glob.glob(pattern))
    if not files: return None
    return files[-1]

def get_grid_ij(lat, lon, projparams, lats, lons):
    p = pyproj.Proj(projparams)
    X_grid, Y_grid = p(lons, lats)
    x_start, x_end = X_grid[0, 0], X_grid[0, -1]
    y_start, y_end = Y_grid[0, 0], Y_grid[-1, 0]
    rows, cols = X_grid.shape

    target_x, target_y = p(lon, lat)
    i_idx = (target_x - x_start) / (x_end - x_start) * (cols - 1)
    j_idx = (target_y - y_start) / (y_end - y_start) * (rows - 1)
    
    return j_idx, i_idx

def get_fractional_ij(lat, lon, lats, lons):
    lat_rad = np.radians(lat)
    dist_sq = (lats - lat)**2 + ((lons - lon) * np.cos(lat_rad))**2
    j, i = np.unravel_index(np.argmin(dist_sq, axis=None), dist_sq.shape)
    
    if j == 0 or j == lats.shape[0]-1 or i == 0 or i == lats.shape[1]-1:
        return float(j), float(i)
        
    dlat_di = (lats[j, i+1] - lats[j, i-1]) / 2.0
    dlat_dj = (lats[j+1, i] - lats[j-1, i]) / 2.0
    dlon_di = ((lons[j, i+1] - lons[j, i-1] + 180) % 360 - 180) / 2.0
    dlon_dj = ((lons[j+1, i] - lons[j-1, i] + 180) % 360 - 180) / 2.0
    
    det = (dlat_dj * dlon_di) - (dlat_di * dlon_dj)
    if det == 0: return float(j), float(i)
        
    delta_lat = lat - lats[j, i]
    delta_lon = (lon - lons[j, i] + 180) % 360 - 180
    
    dj = (dlon_di * delta_lat - dlat_di * delta_lon) / det
    di = (-dlon_dj * delta_lat + dlat_dj * delta_lon) / det
    
    dj = max(-1.0, min(1.0, dj))
    di = max(-1.0, min(1.0, di))
    
    return float(j + dj), float(i + di)

def to_json_list(arr, decimals=1):
    if len(arr) == 0: return []
    return [round(float(x), decimals) if not np.isnan(x) else None for x in arr]

@app.route('/point_forecast', methods=['GET'])
def point_forecast():
    try:
        lat = float(request.args.get('lat'))
        lon = float(request.args.get('lon'))
        model = request.args.get('model', 'wrf2km').lower()

        zarr_path = get_latest_zarr_path(model)
        if not zarr_path: return jsonify({'error': f'No Zarr stores found for model: {model}'}), 404

        ds = xr.open_zarr(zarr_path)
        ds = ds.assign_coords({"south_north": np.arange(ds.sizes["south_north"]), "west_east": np.arange(ds.sizes["west_east"])})

        projparams = None
        if 'TRUELAT1' in ds.attrs:
            projparams = {'proj': 'lcc', 'lat_1': ds.attrs.get('TRUELAT1', 33.0), 'lat_2': ds.attrs.get('TRUELAT2', 45.0), 'lat_0': ds.attrs.get('MOAD_CEN_LAT', 39.0), 'lon_0': ds.attrs.get('STAND_LON', -105.0), 'a': 6370000, 'b': 6370000}
        
        if not projparams:
            for var in ds.variables.values():
                if 'grid_mapping_name' in var.attrs and var.attrs['grid_mapping_name'] == 'lambert_conformal_conic':
                    std_par = var.attrs.get('standard_parallel', [25.0, 25.0])
                    lat_1 = std_par[0] if isinstance(std_par, (list, tuple, np.ndarray)) else std_par
                    lat_2 = std_par[1] if isinstance(std_par, (list, tuple, np.ndarray)) and len(std_par) > 1 else lat_1
                    projparams = {'proj': 'lcc', 'lat_1': lat_1, 'lat_2': lat_2, 'lat_0': var.attrs.get('latitude_of_projection_origin', 25.0), 'lon_0': var.attrs.get('longitude_of_central_meridian', -95.0), 'a': var.attrs.get('earth_radius', 6371229.0), 'b': var.attrs.get('earth_radius', 6371229.0)}
                    break

        if not projparams:
            if model == 'hrrr': projparams = {'proj': 'lcc', 'lat_1': 38.5, 'lat_2': 38.5, 'lat_0': 38.5, 'lon_0': -97.5, 'a': 6371229.0, 'b': 6371229.0}
            elif model in ['ndfd', 'nbm']: projparams = {'proj': 'lcc', 'lat_1': 25.0, 'lat_2': 25.0, 'lat_0': 25.0, 'lon_0': -95.0, 'a': 6371200.0, 'b': 6371200.0}

        lats = ds['XLAT'][0].values if ds['XLAT'].ndim == 3 else ds['XLAT'].values
        lons = ds['XLONG'][0].values if ds['XLONG'].ndim == 3 else ds['XLONG'].values
        
        if projparams: j_idx, i_idx = get_grid_ij(lat, lon, projparams, lats, lons)
        else: j_idx, i_idx = get_fractional_ij(lat, lon, lats, lons)

        j_int, i_int = int(np.floor(j_idx)), int(np.floor(i_idx))
        buffer = 15
        min_j, max_j = max(0, j_int - buffer), min(ds.sizes["south_north"], j_int + buffer + 1)
        min_i, max_i = max(0, i_int - buffer), min(ds.sizes["west_east"], i_int + buffer + 1)
        
        ds_subset = ds.isel(south_north=slice(min_j, max_j), west_east=slice(min_i, max_i)).compute()
        j_rel, i_rel = j_idx - min_j, i_idx - min_i

        valid_masks = {}
        for v in ds_subset.data_vars:
            if 'time' in ds_subset[v].dims: valid_masks[v] = ds_subset[v].notnull().any(dim=['south_north', 'west_east']).values
            else: valid_masks[v] = ds_subset[v].notnull().any().values

        ds_subset_filled = ds_subset.fillna(0.0)

        # --- THE FIX: Convert Spd/Dir to U/V Vectors BEFORE Interpolation! ---
        if 'WIND_SPD' in ds_subset_filled and 'WIND_DIR' in ds_subset_filled:
            spd = ds_subset_filled['WIND_SPD'].values
            dir_rad = np.radians(ds_subset_filled['WIND_DIR'].values)
            
            u_wind = -spd * np.sin(dir_rad)
            v_wind = -spd * np.cos(dir_rad)
            
            ds_subset_filled['U_WIND'] = (ds_subset_filled['WIND_SPD'].dims, u_wind)
            ds_subset_filled['V_WIND'] = (ds_subset_filled['WIND_DIR'].dims, v_wind)
            ds_subset_filled = ds_subset_filled.drop_vars(['WIND_SPD', 'WIND_DIR'])
            
            if 'WIND_SPD' in valid_masks: valid_masks['U_WIND'] = valid_masks['WIND_SPD']
            if 'WIND_DIR' in valid_masks: valid_masks['V_WIND'] = valid_masks['WIND_DIR']

        interpolated = {}
        for v in ds_subset_filled.data_vars:
            data_arr = ds_subset_filled[v].values
            if 'time' in ds_subset_filled[v].dims:
                vals = []
                for t in range(data_arr.shape[0]):
                    val = float(map_coordinates(data_arr[t], [[j_rel], [i_rel]], order=3, mode='nearest')[0])
                    if v in ['RAIN', 'SNOW', 'WIND_GST']: val = max(0.0, val)
                    elif v == 'CLOUD': val = max(0.0, min(100.0, val))
                    vals.append(val)
                arr = np.array(vals)
            else:
                val = float(map_coordinates(data_arr, [[j_rel], [i_rel]], order=3, mode='nearest')[0])
                if v in ['RAIN', 'SNOW', 'WIND_GST']: val = max(0.0, val)
                elif v == 'CLOUD': val = max(0.0, min(100.0, val))
                arr = np.array([val])
                
            mask = valid_masks.get(v, True)
            if isinstance(mask, np.ndarray): arr[~mask] = np.nan
            else:
                if not mask: arr[:] = np.nan
            interpolated[v] = arr

        # --- RECONSTRUCT CORRECTED ANGLES AND SPEEDS ---
        if 'U_WIND' in interpolated and 'V_WIND' in interpolated:
            u_interp = interpolated['U_WIND']
            v_interp = interpolated['V_WIND']
            
            interpolated['WIND_SPD'] = np.sqrt(u_interp**2 + v_interp**2)
            math_deg = np.degrees(np.arctan2(v_interp, u_interp))
            interpolated['WIND_DIR'] = (270 - math_deg) % 360

        t_f = interpolated['T2'] if 'T2' in interpolated else []
        td_f = interpolated['TD2'] if 'TD2' in interpolated else []
        wind_speed = interpolated['WIND_SPD'] if 'WIND_SPD' in interpolated else []
        wind_dir = interpolated['WIND_DIR'] if 'WIND_DIR' in interpolated else []
        wind_gust = interpolated['WIND_GST'] if 'WIND_GST' in interpolated else []
        accum_precip = interpolated['RAIN'] if 'RAIN' in interpolated else []
        accum_snow = interpolated['SNOW'] if 'SNOW' in interpolated else []

        def calculate_buckets(accum_array):
            if len(accum_array) == 0: return []
            s = pd.Series(accum_array)
            if s.isna().all(): return s.values
            s.iloc[0] = 0.0
            baseline = s.ffill().shift(1)
            diff = s - baseline
            diff.iloc[0] = s.iloc[0]
            return diff.clip(lower=0).values

        clean_hourly_precip = calculate_buckets(accum_precip)
        clean_hourly_snow = calculate_buckets(accum_snow)

        with np.errstate(invalid='ignore', divide='ignore'):
            t_c = (t_f - 32) / 1.8
            td_c = (td_f - 32) / 1.8
            e = np.exp((17.625 * td_c) / (243.04 + td_c))
            e_s = np.exp((17.625 * t_c) / (243.04 + t_c))
            rh = np.clip(100.0 * (e / e_s), 0, 100)

        time_vals = ds_subset['time'].values
        time_range = pd.DatetimeIndex(time_vals) if pd.api.types.is_datetime64_any_dtype(time_vals) else pd.date_range(start=ds.attrs.get('init_time', '2026-03-21_00:00:00').replace('_', ' '), periods=len(time_vals), freq='h')
        
        if 'HGT' in interpolated:
            hgt_val = np.atleast_1d(interpolated['HGT'])[0]
            elevation = int(np.round(hgt_val)) if not np.isnan(hgt_val) else "Unknown"
        else:
            elevation = "Unknown"
            
        init_time = pd.to_datetime(time_range[0]).isoformat() if 'init_time' not in ds.attrs else ds.attrs['init_time'].replace('_', 'T')

        response_data = {
            'init_time': init_time, 'model': model.upper(),
            'times': [pd.to_datetime(t).isoformat() for t in time_range],
            'elevation': elevation, 'temperature': to_json_list(t_f, 1),
            'dewpoint': to_json_list(td_f, 1), 'rh': to_json_list(rh, 0), 
            'wind_speed': to_json_list(wind_speed, 1), 'wind_gust': to_json_list(wind_gust, 1),
            'wind_dir': [int(round(x)) if not np.isnan(x) else None for x in wind_dir],
            'sky': to_json_list(interpolated['CLOUD'] if 'CLOUD' in interpolated else [], 0), 
            'precip': to_json_list(clean_hourly_precip, 3), 'snow': to_json_list(clean_hourly_snow, 2),
            'accum_precip': to_json_list(accum_precip, 3), 'accum_snow': to_json_list(accum_snow, 2)
        }
        return jsonify(response_data)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
