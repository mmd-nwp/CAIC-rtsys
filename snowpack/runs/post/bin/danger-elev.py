import json
import mysql.connector
from datetime import date,datetime
import argparse
import sys

# =================================================================
# 1. CONFIGURATION
# =================================================================
MASTER_GEOJSON = '/home/caic/www/snowpack/include/caic_polygons_elev.geojson'

DB_CONFIG = {
    'host': 'localhost',
    'user': 'caic',
    'password': 'steepndeep',
    'database': 'snowpack'
}

# =================================================================
# 2. DATABASE UTILITY
# =================================================================
def fetch_danger(target_date):
    """Fetches danger ratings from the database for a specific date."""
    danger_lookup = {}
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor(dictionary=True)
        
        query = "SELECT polygon, atl, ntl, btl FROM polyDanger WHERE date = %s"
        cursor.execute(query, (target_date,))
        
        rows = cursor.fetchall()
        for row in rows:
            poly_id = row['polygon']
            danger_lookup[poly_id] = {
                '>3500m': row['atl'],
                '3200-3500m': row['ntl'],
                '<3200m': row['btl']
            }
            
        cursor.close()
        conn.close()
        print(f"Loaded {len(danger_lookup)} danger records for {target_date}.")
        
    except mysql.connector.Error as err:
        print(f"Database Error: {err}")
        sys.exit(1) # Stop the script if the DB connection fails
        
    return danger_lookup

# =================================================================
# 3. MAIN EXECUTION
# =================================================================
if __name__ == '__main__':
    # Set up the command line argument parser
    parser = argparse.ArgumentParser(description="Inject daily avalanche danger into master geometry.")
    parser.add_argument(
        '--time', 
        type=str, 
        default=date.today().strftime('%Y-%m-%d'), 
        help="Date to fetch danger ratings for (Format: YYYY-MM-DD). Defaults to today."
    )
    
    # Parse the arguments
    args = parser.parse_args()
    target_date = args.time

    print(f"--- Running Danger Update for: {target_date} ---")
    danger_lookup = fetch_danger(target_date)

    if not danger_lookup:
        print(f"WARNING: No danger ratings found in the database for {target_date}.")

    print(f"Loading master geometry from {MASTER_GEOJSON}...")
    try:
        with open(MASTER_GEOJSON, 'r', encoding='utf-8') as f:
            geojson_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {MASTER_GEOJSON} not found. Run the Master Geometry script first.")
        sys.exit(1)

    print("Injecting danger ratings...")
    # Loop through every polygon in the master file
    for feature in geojson_data['features']:
        props = feature['properties']
        poly_num = props.get('polygon_number')
        elev_band = props.get('elev_band')
        
        # Default to 0 (Missing Data)
        rating = 0 
        
        # Look up the rating in our database dictionary
        if poly_num in danger_lookup and elev_band in danger_lookup[poly_num]:
            db_val = danger_lookup[poly_num][elev_band]
            if db_val is not None:
                rating = int(db_val)
                
        # Inject the rating into the GeoJSON properties
        props['danger_rating'] = rating

    # Format output filename as YYMMDD.geojson 
    date_obj = datetime.strptime(target_date, '%Y-%m-%d')
    short_date = date_obj.strftime('%y%m%d')
    output_filename = f"/home/caic/www/snowpack/json/danger-poly/{short_date}.geojson"
    
    print(f"Saving output to {output_filename}...")
    # Minify and save
    with open(output_filename, 'w', encoding='utf-8') as f:
        json.dump(geojson_data, f, separators=(',', ':'))
        
    print("Update complete!")
