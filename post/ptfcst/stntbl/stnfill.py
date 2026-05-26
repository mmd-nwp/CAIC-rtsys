import mysql.connector

def is_float(value):
    try:
        float(value)
        return True
    except ValueError:
        return False

def process_station_data(file_path):
    db_config = {
        'host': 'localhost',
        'user': 'caic',
        'password': 'steepndeep',
        'database': 'ptfcst'
    }

    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        insert_query = """
        REPLACE INTO stnList (stnName, nameOrder, stnZone, zoneOrder, longName, lat, lon)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """

        zoneOrder = -1
        nameOrder = -1
        prevZone  = ""
        with open(file_path, 'r') as file:
            for line_num, line in enumerate(file, 1):
                # Skip completely blank lines
                if not line.strip():
                    continue
                
                try:
                    stnName  = line[0:10].strip()
                    lat      = line[11:18].strip()
                    lon      = line[19:28].strip()
                    stnZone  = line[29:40].strip()
                    longName = line[42:].strip()  

                    nameOrder += 1
                    if stnZone != prevZone:
                      zoneOrder += 1
                      nameOrder = 0

                    # Convert to integers, substituting None (NULL in MySQL) if blank
                    lat_val  = lat if is_float(lat) else None
                    lon_val  = lon if is_float(lon) else None
                    print(stnZone, zoneOrder, stnName, nameOrder, lat_val, lon_val, longName)

                    cursor.execute(insert_query, (stnName, nameOrder, stnZone, zoneOrder, longName, lat_val, lon_val))
                    prevZone = stnZone
                
                except Exception as e:
                    print(f"Error parsing line {line_num}: {line.strip()}")
                    print(f"Details: {e}")

        conn.commit()
        print("Import successful.")

    except mysql.connector.Error as err:
        print(f"Database connection or execution error: {err}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

if __name__ == "__main__":
    process_station_data('stnnames.txt')
