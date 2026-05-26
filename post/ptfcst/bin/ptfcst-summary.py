import mysql.connector
import numpy as np
import math
import argparse
from datetime import datetime, timedelta

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'user': 'caic',
    'password': 'steepndeep',
    'database': 'ptfcst'
}

def get_station_names():
    """Fetches the list of station names from the database."""
    stations = []
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT stnName FROM stnList")
        for row in cursor.fetchall():
            stations.append(row['stnName'])
    except mysql.connector.Error as err:
        print(f"Database Error: {err}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()
    return stations

def get_station_arrays(stn_name, model_id, init_time=None):
    """Reads forecast data and unpacks it, also returning the actual initialization time."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor(dictionary=True)
        
        if init_time:
            query = """
                SELECT initTime, validTime, shltrTemp, shltrUwnd, shltrVwnd, shltrGust, cloud, aPcp, aSnow, aSnow10, aSnow90 
                FROM stnPtfcst 
                WHERE stnName = %s AND modelId = %s AND initTime = %s
                ORDER BY validTime
            """
            cursor.execute(query, (stn_name, model_id, init_time))
        else:
            query = """
                SELECT initTime, validTime, shltrTemp, shltrUwnd, shltrVwnd, shltrGust, cloud, aPcp, aSnow, aSnow10, aSnow90 
                FROM stnPtfcst 
                WHERE stnName = %s AND modelId = %s
                  AND initTime = (
                      SELECT MAX(initTime) 
                      FROM stnPtfcst 
                      WHERE stnName = %s AND modelId = %s
                  )
                ORDER BY validTime
            """
            cursor.execute(query, (stn_name, model_id, stn_name, model_id))
            
        rows = cursor.fetchall()
        
    except mysql.connector.Error as err:
        print(f"Database Error: {err}")
        return None, None
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

    if not rows:
        return None, None

    # Grab the actual initTime from the very first row
    actual_init_time = rows[0]['initTime']

    data = {
        'times': np.array([row['validTime'] for row in rows]),
        'temps': np.array([row['shltrTemp'] / 10.0 if row['shltrTemp'] is not None else np.nan for row in rows], dtype=float),
        'u_wnds': np.array([row['shltrUwnd'] / 10.0 if row['shltrUwnd'] is not None else np.nan for row in rows], dtype=float),
        'v_wnds': np.array([row['shltrVwnd'] / 10.0 if row['shltrVwnd'] is not None else np.nan for row in rows], dtype=float),
        'gusts': np.array([row['shltrGust'] / 10.0 if row['shltrGust'] is not None else np.nan for row in rows], dtype=float),
        'clouds': np.array([row['cloud'] if row['cloud'] is not None else np.nan for row in rows], dtype=float),
        'pcp': np.array([row['aPcp'] / 100.0 if row['aPcp'] is not None else np.nan for row in rows], dtype=float),
        'snow': np.array([row['aSnow'] / 10.0 if row['aSnow'] is not None else np.nan for row in rows], dtype=float),
        'snow10': np.array([row['aSnow10'] / 10.0 if row['aSnow10'] is not None else np.nan for row in rows], dtype=float),
        'snow90': np.array([row['aSnow90'] / 10.0 if row['aSnow90'] is not None else np.nan for row in rows], dtype=float)
    }
    
    return data, actual_init_time

def degrees_to_cardinal(d):
    """Converts a meteorological wind direction in degrees to a 16-point compass string."""
    dirs = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 
            'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']
    ix = int((d + 11.25) / 22.5) % 16
    return dirs[ix]

def summarize_station_blocks(stn_name, stn_data, init_time):
    """Slices data into 12-hour 00Z/12Z blocks anchored absolutely to the initTime."""
    times = stn_data['times']
    
    if len(times) == 0:
        return []
        
    # Snap the initTime BACK to the nearest 00Z or 12Z boundary to create a rigid grid
    anchor_time = init_time.replace(hour=(init_time.hour // 12) * 12, minute=0, second=0, microsecond=0)
    
    current_bound = anchor_time
    last_time = times[-1]
    
    summaries = []
    period_idx = 0
    
    while current_bound < last_time:
        next_bound = current_bound + timedelta(hours=12)
        
        mask = (times >= current_bound) & (times <= next_bound)
        idx = np.where(mask)[0]
        
        # If there is ANY data in this rigidly defined 12-hour window, process it!
        if len(idx) > 0:
            block_temps = stn_data['temps'][idx]
            block_u = stn_data['u_wnds'][idx]
            block_v = stn_data['v_wnds'][idx]
            block_gusts = stn_data['gusts'][idx]
            block_clouds = stn_data['clouds'][idx]
            block_pcp = stn_data['pcp'][idx]
            block_snow = stn_data['snow'][idx]
            block_snow10 = stn_data['snow10'][idx]
            block_snow90 = stn_data['snow90'][idx]
            
            # --- Temperature Logic ---
            is_12z_to_00z = (current_bound.hour == 12)
            if np.isnan(block_temps).all():
                temp_val = np.nan
                temp_type = "Max" if is_12z_to_00z else "Min"
            else:
                temp_val = np.nanmax(block_temps) if is_12z_to_00z else np.nanmin(block_temps)
                temp_type = "Max" if is_12z_to_00z else "Min"
            
            # --- Wind Logic ---
            if np.isnan(block_u).all() or np.isnan(block_v).all():
                avg_wspd = np.nan
                avg_wdir_str = "M"
            else:
                avg_u = np.nanmean(block_u)
                avg_v = np.nanmean(block_v)
                avg_wspd = math.sqrt(avg_u**2 + avg_v**2)
                
                math_deg = math.degrees(math.atan2(avg_v, avg_u))
                avg_wdir_deg = (270 - math_deg) % 360
                avg_wdir_str = degrees_to_cardinal(avg_wdir_deg)
            
            # --- Gust Logic ---
            avg_gust = np.nan if np.isnan(block_gusts).all() else np.nanmean(block_gusts)
            
            # --- Cloud Cover Logic ---
            if np.isnan(block_clouds).all():
                cloud_cat = "M"
            else:
                avg_cloud = np.nanmean(block_clouds)
                if avg_cloud == 0:
                    cloud_cat = "CLR"
                elif avg_cloud <= 10:
                    cloud_cat = "FEW"
                elif avg_cloud <= 50:
                    cloud_cat = "SCT"
                elif avg_cloud <= 90:
                    cloud_cat = "BKN"
                else:
                    cloud_cat = "OVC"

            # --- Precipitation & Deterministic Snow Logic ---
            period_pcp = np.nan if np.isnan(block_pcp).all() else np.nanmax(block_pcp) - np.nanmin(block_pcp)
            period_snow = np.nan if np.isnan(block_snow).all() else np.nanmax(block_snow) - np.nanmin(block_snow)

            # --- Strict Percentile Snow Logic ---
            # If the final point in the 12-hour block is NaN, reject the entire block's percentile accumulation
            if len(block_snow10) == 0 or np.isnan(block_snow10[-1]):
                period_snow10 = np.nan
            else:
                period_snow10 = np.nanmax(block_snow10) - np.nanmin(block_snow10)

            if len(block_snow90) == 0 or np.isnan(block_snow90[-1]):
                period_snow90 = np.nan
            else:
                period_snow90 = np.nanmax(block_snow90) - np.nanmin(block_snow90)

            summaries.append({
                'period': period_idx,
                'start_time': current_bound,
                'end_time': next_bound,
                'pts': len(idx),
                'temp_type': temp_type,
                'temp_val': temp_val,
                'wspd': avg_wspd,
                'wdir': avg_wdir_str,
                'gust': avg_gust,
                'clouds': cloud_cat,
                'pcp': period_pcp,
                'snow': period_snow,
                'snow10': period_snow10,
                'snow90': period_snow90
            })
            
        current_bound = next_bound
        period_idx += 1
        
    return summaries

def insert_summaries_to_db(stn_name, model_id, init_time, summaries):
    """Inserts the calculated 12-hour summaries into the stnSummary table as scaled integers."""
    if not summaries:
        return

    db_rows = []
    
    # Helper to safely multiply, round, and convert to integer for database storage
    def scale_and_int(val, multiplier):
        if val is None or (isinstance(val, float) and np.isnan(val)):
            return None
        return int(round(float(val) * multiplier))

    for s in summaries:
        db_rows.append((
            stn_name,
            model_id,
            init_time,
            s['period'],                          # timePeriod
            scale_and_int(s['temp_val'], 10),     # temp (* 10)
            scale_and_int(s['wspd'], 10),         # speed (* 10)
            s['wdir'],                            # direction (string, e.g., "NNE")
            scale_and_int(s['gust'], 10),         # gust (* 10)
            s['clouds'],                          # sky (string, e.g., "OVC")
            scale_and_int(s['pcp'], 100),         # aPcp (* 100)
            scale_and_int(s['snow'], 10),         # aSnow (* 10)
            scale_and_int(s['snow10'], 10),       # aSnow10 (* 10)
            scale_and_int(s['snow90'], 10)        # aSnow90 (* 10)
        ))

    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()

        insert_query = """
        REPLACE INTO stnSummary 
        (stnName, modelId, initTime, timePeriod, temp, speed, direction, gust, sky, aPcp, aSnow, aSnow10, aSnow90)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        cursor.executemany(insert_query, db_rows)
        conn.commit()
        print(f"  -> Successfully saved {cursor.rowcount} scaled summaries to the database.")

    except mysql.connector.Error as err:
        print(f"  -> Database Insertion Error: {err}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Summarize station forecast data into 12-hour blocks.")
    parser.add_argument('--model', type=str, default='hrrr', 
                        help='Model ID to summarize (default: hrrr)')
    parser.add_argument('--time', type=str, default=None,
                        help='Initial model run time in YYYYMMDDHH format (e.g., 2026031212). Defaults to latest run.')
    
    args = parser.parse_args()
    model_id = args.model.lower()
    
    init_dt = None
    if args.time:
        try:
            init_dt = datetime.strptime(args.time, '%Y%m%d%H')
            print(f"Targeting specific run: {model_id.upper()} at {init_dt} UTC")
        except ValueError:
            print("Error: --time must be in YYYYMMDDHH format (e.g., 2026031212)")
            exit(1)
    else:
        print(f"Targeting latest available run for: {model_id.upper()}")

    # Process all stations in the database
    stations = get_station_names()
    
    if not stations:
        print("No stations found in the database. Exiting.")
        exit(0)
        
    print(f"Found {len(stations)} stations to process.\n")
    
    for stn_name in stations:
        stn_data, actual_init_time = get_station_arrays(stn_name, model_id, init_dt)
        
        if stn_data:
            block_summaries = summarize_station_blocks(stn_name, stn_data, actual_init_time)
            
            print(f"\n=== {stn_name.upper()} 12-Hour Summaries ===")
            for s in block_summaries:
                start_str = s['start_time'].strftime('%m/%d %H:%MZ')
                end_str = s['end_time'].strftime('%H:%MZ')
                
                print(f"Period {s['period']} ({start_str} to {end_str}) | Points: {s['pts']}")
                print(f"  -> {s['temp_type']} Temp:  {s['temp_val']:.1f} °F")
                print(f"  -> Sky Cond:  {s['clouds']}")
                print(f"  -> Avg Wind:  {s['wspd']:.1f} mph from {s['wdir']} (Gusts to {s['gust']:.1f} mph)")
                
                pcp_str = f"{s['pcp']:.2f} in" if not np.isnan(s['pcp']) else "M"
                snow_str = f"{s['snow']:.1f} in" if not np.isnan(s['snow']) else "M"
                
                # Expand console output to show percentiles if they exist
                if not np.isnan(s['snow10']) and not np.isnan(s['snow90']):
                    snow_str += f"  (10th: {s['snow10']:.1f}\", 90th: {s['snow90']:.1f}\")"
                    
                print(f"  -> Precip:    {pcp_str}")
                print(f"  -> Snow:      {snow_str}")
                print("-" * 50)
                
            # Write to the Database
            insert_summaries_to_db(stn_name, model_id, actual_init_time, block_summaries)
            
        else:
            print(f"No forecast data found for {stn_name}.")
