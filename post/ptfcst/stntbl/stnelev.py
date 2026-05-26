import os
import argparse
import pygrib
import numpy as np
import mysql.connector
import pyproj
from scipy.ndimage import map_coordinates
from datetime import datetime, timezone
from netCDF4 import Dataset

# --- Configuration ---
DB_CONFIG = {
    'host': 'localhost',
    'user': 'caic',
    'password': 'steepndeep',
    'database': 'ptfcst'
}

# --- Grid Subsetting Function ---
def get_grid_subset_indices(lats, lons, projparams, stations, buffer=15):
    """Calculates the bounding box indices of the grid that cover the station list."""
    p = pyproj.Proj(projparams)
    X_grid, Y_grid = p(lons, lats)
    x_start, x_end = X_grid[0, 0], X_grid[0, -1]
    y_start, y_end = Y_grid[0, 0], Y_grid[-1, 0]
    rows, cols = X_grid.shape

    min_i, max_i, min_j, max_j = cols, 0, rows, 0

    for stn in stations:
        stn_x, stn_y = p(float(stn['lon']), float(stn['lat']))
        i_idx = int((stn_x - x_start) / (x_end - x_start) * (cols - 1))
        j_idx = int((stn_y - y_start) / (y_end - y_start) * (rows - 1))
        min_i, max_i = min(min_i, i_idx), max(max_i, i_idx)
        min_j, max_j = min(min_j, j_idx), max(max_j, j_idx)

    min_j, max_j = max(0, min_j - buffer), min(rows, max_j + buffer)
    min_i, max_i = max(0, min_i - buffer), min(cols, max_i + buffer)
    return (slice(min_j, max_j), slice(min_i, max_i))

# --- Database Functions ---
def get_station_locations():
    """Fetches station metadata from the database."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor(dictionary=True) 
        cursor.execute("SELECT stnName, lat, lon FROM stnList")
        stations = cursor.fetchall()
        return stations
    except mysql.connector.Error as err:
        print(f"Database error: {err}")
        return []
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

def update_elevations_in_db(station_elevations, model_id):
    """Safely updates extracted elevations into the stnList table without overwriting other columns."""
    if not station_elevations:
        return

    # Map the model ID to the exact MySQL column name
    if model_id == 'hrrr':
        column_name = 'hrrrElev'
    elif model_id == 'ndfd':
        column_name = 'nwsElev'
    elif model_id == 'wrf2km':
        column_name = 'wrf2kmElev'
    elif model_id == 'wrf4km':
        column_name = 'wrf4kmElev'
    else:
        print(f"Error: Unknown model ID '{model_id}' for database update.")
        return

    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # The UPDATE command surgically targets the specific column and row
        update_query = f"UPDATE stnList SET {column_name} = %s WHERE stnName = %s"
        
        update_data = []
        for stn, elev in station_elevations.items():
            if elev is not None and not np.isnan(elev):
                update_data.append((int(elev), stn))

        if update_data:
            cursor.executemany(update_query, update_data)
            conn.commit()
            print(f"\nSUCCESS: Updated {cursor.rowcount} stations in the '{column_name}' column of stnList.")
        else:
            print("\nNo valid elevations found to update.")

    except mysql.connector.Error as err:
        print(f"\nDatabase Update Error: {err}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

# --- HRRR Extraction ---
def extract_hrrr_elevation(file_path, stations):
    """Extracts surface Geopotential Height (elevation) from an HRRR GRIB2 file."""
    elevation_grid = None
    master_grid = None
    
    try: 
        grbs = pygrib.open(file_path)
    except Exception as e: 
        print(f"Error opening GRIB file {file_path}: {e}")
        return None, None

    for msg in grbs:
        cat = getattr(msg, 'parameterCategory', None)
        num = getattr(msg, 'parameterNumber', None)
        type_of_level = getattr(msg, 'typeOfLevel', None)

        # HRRR Elevation is Category 3 (Mass), Number 5 (Geopotential Height), at the Surface
        if cat == 3 and num == 5 and type_of_level == 'surface':
            raw_lats, raw_lons = msg.latlons()
            projparams = getattr(msg, 'projparams', None)
            slice_obj = get_grid_subset_indices(raw_lats, raw_lons, projparams, stations)
            master_grid = (raw_lats[slice_obj], raw_lons[slice_obj], projparams, slice_obj)
            
            elevation_grid = msg.values[slice_obj]
            break

    grbs.close()
    return elevation_grid, master_grid

# --- WRF Extraction ---
def extract_wrf_elevation(file_path, stations):
    """Extracts terrain height from a WRF NetCDF file."""
    elevation_grid = None
    master_grid = None
    
    try: 
        nc = Dataset(file_path, 'r')
    except Exception as e: 
        print(f"Error opening NetCDF file {file_path}: {e}")
        return None, None

    raw_lats = nc.variables['XLAT'][0, :, :]
    raw_lons = nc.variables['XLONG'][0, :, :]
    
    try:
        if getattr(nc, 'MAP_PROJ', 1) == 1:
            wrf_projparams = {'proj': 'lcc', 'lat_1': getattr(nc, 'TRUELAT1'), 'lat_2': getattr(nc, 'TRUELAT2'), 'lat_0': getattr(nc, 'MOAD_CEN_LAT'), 'lon_0': getattr(nc, 'STAND_LON'), 'R': 6370000.0}
        else: 
            wrf_projparams = {}
    except: 
        wrf_projparams = {}
        
    slice_obj = get_grid_subset_indices(raw_lats, raw_lons, wrf_projparams, stations)
    master_grid = (raw_lats[slice_obj], raw_lons[slice_obj], wrf_projparams, slice_obj)

    s_y, s_x = slice_obj
    
    # WRF Terrain Height is typically stored in the 'HGT' variable
    if 'HGT' in nc.variables:
        elevation_grid = nc.variables['HGT'][0, s_y, s_x]
    
    nc.close()
    return elevation_grid, master_grid

# --- Interpolation ---
def interpolate_elevation(elevation_grid, master_grid, stations):
    """Interpolates the subsetted grid to the exact station coordinates."""
    lats, lons, projparams, _ = master_grid
    p = pyproj.Proj(projparams)
    X_grid, Y_grid = p(lons, lats)
    x_start, x_end = X_grid[0, 0], X_grid[0, -1]
    y_start, y_end = Y_grid[0, 0], Y_grid[-1, 0]
    rows, cols = X_grid.shape
    
    results = {}

    for stn in stations:
        stn_name = stn['stnName']
        stn_x, stn_y = p(float(stn['lon']), float(stn['lat']))
        
        i_idx = (stn_x - x_start) / (x_end - x_start) * (cols - 1)
        j_idx = (stn_y - y_start) / (y_end - y_start) * (rows - 1)
        
        if not (0 <= i_idx <= cols - 1 and 0 <= j_idx <= rows - 1):
            results[stn_name] = np.nan
            continue
            
        # Extract the elevation using piecewise bicubic spline (order=3)
        val = float(map_coordinates(elevation_grid, [[j_idx], [i_idx]], order=3, mode='nearest')[0])
        
        # Convert meters to feet
        val_feet = val * 3.28084
        results[stn_name] = round(val_feet)

    return results

# --- Main Execution ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract and update station elevations in the database.")
    parser.add_argument('--model', type=str, required=True, choices=['hrrr', 'wrf2km', 'wrf4km', 'ndfd'], help='Model ID to process.')
    parser.add_argument('--time', type=str, help='Initial model run time in YYYYMMDDHH format (e.g., 2026031212). Defaults to latest run.')
    
    args = parser.parse_args()
    model_id = args.model.lower()

    if args.time:
        init_dt = datetime.strptime(args.time, '%Y%m%d%H')
    else:
        now_utc = datetime.now(timezone.utc).replace(tzinfo=None) 
        if model_id == 'hrrr': 
            init_dt = datetime(now_utc.year, now_utc.month, now_utc.day, now_utc.hour, 0)
        else: 
            init_dt = datetime(now_utc.year, now_utc.month, now_utc.day, (now_utc.hour // 6) * 6, 0)

    # Determine file path based on your existing structure
    file_prefix = init_dt.strftime('%y%j%H00')
    if model_id.startswith('wrf'):
        base_dir = f"/model/caic/{'2km' if model_id == 'wrf2km' else '4km'}/wrf/{file_prefix}"
        target_file = os.path.join(base_dir, f"wrfout_d02_{init_dt.strftime('%Y-%m-%d_%H:%M:00')}")
    elif model_id.startswith('hrrr'): # HRRR
        base_dir = f"/data/noaaport/grids/{model_id}/grib2"
        target_file = os.path.join(base_dir, f"{file_prefix}0000")
    else:
        target_file = "ndfd_terrain"

    print(f"Targeting file: {target_file}")
    
    if not os.path.exists(target_file):
        print(f"Error: Could not find initialization file for {model_id.upper()} at {target_file}")
        exit(1)

    station_list = get_station_locations()
    if not station_list:
        print("Error: Could not fetch station list from database.")
        exit(1)

    print(f"Extracting elevation grids from {model_id.upper()}...")
    
    if model_id.startswith('wrf'):
        elev_grid, master_grid = extract_wrf_elevation(target_file, station_list)
    else:
        elev_grid, master_grid = extract_hrrr_elevation(target_file, station_list)

    if elev_grid is not None and master_grid is not None:
        print("Interpolating subset grid to station coordinates...\n")
        station_elevations = interpolate_elevation(elev_grid, master_grid, station_list)
        
        print(f"=== {model_id.upper()} STATION ELEVATIONS (Feet) ===")
        for stn, elev in station_elevations.items():
            print(f"{stn.ljust(15)}: {elev} ft")
            
        # Push the updates securely into the database!
        update_elevations_in_db(station_elevations, model_id)
        
    else:
        print("Failed to extract elevation data from the model file.")
