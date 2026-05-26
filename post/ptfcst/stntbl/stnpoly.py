import os
import json
import argparse
import mysql.connector
from shapely.geometry import Point, shape

# --- Configuration ---
DB_CONFIG = {
    'host': 'localhost',
    'user': 'caic',
    'password': 'steepndeep',
    'database': 'ptfcst'
}

# --- Database Functions ---
def get_station_locations():
    """Fetches station metadata (name, lat, lon) from the database."""
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

def update_poly_numbers_in_db(update_data):
    """Safely updates the polyNumber column in the stnList table."""
    if not update_data:
        print("No valid polygon matches found to update.")
        return

    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # The UPDATE command specifically targets the polyNumber column
        update_query = "UPDATE stnList SET polyNumber = %s WHERE stnName = %s"
        
        cursor.executemany(update_query, update_data)
        conn.commit()
        print(f"\nSUCCESS: Updated {cursor.rowcount} stations with their respective polygon numbers.")

    except mysql.connector.Error as err:
        print(f"\nDatabase Update Error: {err}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

# --- Geospatial Functions ---
def load_polygons(geojson_path):
    """Loads a GeoJSON file and converts its features to shapely Polygon objects."""
    polygons = []
    
    try:
        with open(geojson_path, 'r') as f:
            geo_data = json.load(f)
            
        for feature in geo_data.get('features', []):
            poly_shape = shape(feature['geometry'])
            poly_num = feature['properties'].get('polygon_number')
            
            if poly_num is not None:
                polygons.append((poly_shape, poly_num))
                
        print(f"Successfully loaded {len(polygons)} polygons from {geojson_path}")
        return polygons
    except Exception as e:
        print(f"Error reading GeoJSON file: {e}")
        return []

def match_stations_to_polygons(stations, polygons):
    """Checks each station coordinate against the polygons to find a match."""
    update_data = []
    unmatched = []

    for stn in stations:
        stn_name = stn['stnName']
        
        # Shapely Points are created using (longitude, latitude)
        try:
            pt = Point(float(stn['lon']), float(stn['lat']))
        except (ValueError, TypeError):
            print(f"Warning: Invalid coordinates for station {stn_name}. Skipping.")
            continue
            
        matched_poly = None
        for poly_shape, poly_num in polygons:
            # Check if the coordinate point falls inside the polygon boundary
            if poly_shape.contains(pt):
                matched_poly = poly_num
                break
                
        if matched_poly is not None:
            update_data.append((matched_poly, stn_name))
        else:
            unmatched.append(stn_name)

    # Print a warning for any stations that fell entirely outside all polygons
    if unmatched:
        print(f"\nWarning: {len(unmatched)} stations did not fall inside any polygon:")
        print(", ".join(unmatched))

    return update_data

# --- Main Execution ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Map station coordinates to GeoJSON polygons and update the database.")
    parser.add_argument('--geojson', type=str, default='colorado_polygons_2025.geojson', 
                        help='Path to the GeoJSON file containing the polygons (default: colorado_polygons_2025.geojson)')

    base_dir = "/home/www/html/snowpack/include"
    args = parser.parse_args()
    geojson_file = os.path.join(base_dir, f"{args.geojson}")

    # 1. Load the polygons from the file
    print("Loading polygons...")
    polygons = load_polygons(args.geojson)
    if not polygons:
        exit(1)

    # 2. Fetch the stations from the database
    print("Fetching station locations from the database...")
    stations = get_station_locations()
    if not stations:
        exit(1)

    print(f"Found {len(stations)} stations. Calculating spatial intersections...")

    # 3. Match stations to polygons via Point-in-Polygon spatial math
    update_data = match_stations_to_polygons(stations, polygons)

    # 4. Push the updates to the database
    if update_data:
        update_poly_numbers_in_db(update_data)
