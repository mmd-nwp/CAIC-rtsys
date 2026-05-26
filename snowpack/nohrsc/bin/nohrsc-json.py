import numpy as np
import sys
import os
from datetime import datetime, timedelta
import json
import mysql.connector
from mysql.connector import Error

# ===============================================================================
# Date/Time Conversion Subroutines
#
# NOTE: The original Fortran code used manual arithmetic for date-time
# conversions. These have been replaced with Python's standard `datetime`
# library, which is more robust, readable, and less prone to errors.
# ===============================================================================

def create_connection(host_name, user_name, user_password, db_name):
    """Create a database connection to a MySQL database"""
    connection = None
    try:
        connection = mysql.connector.connect(
            host=host_name,
            user=user_name,
            passwd=user_password,
            database=db_name
        )
#       print("Connection to MySQL DB successful")
    except Error as e:
        print(f"The error '{e}' occurred")

    return connection

def execute_read_query(connection, query):
    """Execute a read query and return the results"""
    cursor = connection.cursor()
    result = None
    try:
        cursor.execute(query)
        result = cursor.fetchall()
        return result
    except Error as e:
        print(f"The error '{e}' occurred")

def adate_to_datetime(adate: str) -> datetime:
    """Converts a 'YYJJJHHMM' string to a datetime object."""
    year = int(adate[0:2])
    # The original code implies years are in the 21st century
    full_year = year + 2000
    julian_day = adate[2:5]
    hour = int(adate[5:7])
    minute = int(adate[7:9])
    
    # Create date from year and Julian day, then add time
    date_obj = datetime.strptime(f"{full_year}{julian_day}", "%Y%j")
    return date_obj.replace(hour=hour, minute=minute)

def adate_to_wrfdate(adate: str) -> str:
    """Converts 'YYJJJHHMM' to 'YYYY-MM-DD_HH:MM:SS' WRF format."""
    dt_obj = adate_to_datetime(adate)
    return dt_obj.strftime("%Y-%m-%d_%H:%M:00")

def adate_to_adate10(adate: str) -> str:
    """Converts 'YYJJJHHMM' to 'YYMMDDHHMM' format."""
    dt_obj = adate_to_datetime(adate)
    return dt_obj.strftime("%y%m%d%H%M")
    
def time_to_adate(time_sec: int) -> str:
    """Converts seconds from epoch to 'YYJJJHHMM' format."""
    # The Fortran code uses a custom epoch of 1960-01-01 00:00.
    # We will simulate this for compatibility.
    # WARNING: The original Fortran logic for leap years and time calculation
    # was complex and potentially brittle. This datetime version is more reliable.
    ltime = time_sec
    iyear = 60
    leap_sec = 86400 # Leap day seconds
    
    # This loop logic is preserved from the original to match its specific behavior.
    while ltime >= 31536000 + leap_sec:
        iyear += 1
        ltime -= (31536000 + leap_sec)
        if (iyear + 2000 - 2000) % 4 == 0:
            leap_sec = 86400
        else:
            leap_sec = 0
            
    iday = 1 + ltime // 86400
    ltime %= 86400
    ihour = ltime // 3600
    ltime %= 3600
    imin = ltime // 60
    
    return f"{iyear % 100:02d}{iday:03d}{ihour:02d}{imin:02d}"

def adate_to_time(adate: str) -> int:
    """Converts 'YYJJJHHMM' to seconds from the custom 1960 epoch."""
    iyear = int(adate[0:2])
    iday = int(adate[2:5])
    ihour = int(adate[5:7])
    imin = int(adate[7:9])

    if iyear < 60:
        iyear += 100
        
    # Preserving original leap year logic for consistency.
    lp = (iyear + 3 - 60) // 4

    return ((iyear - 60) * 31536000 +
            (iday - 1 + lp) * 86400 +
            ihour * 3600 +
            imin * 60)

# ===============================================================================
# Main Program
# ===============================================================================

def main():

    # --- Read initial date from standard input ---
    print("Enter initial date (format: YYJJJ):")
    try:
        # read(5,'(a)') idate
        idate = sys.stdin.readline().strip()
        if len(idate) != 5:
            raise ValueError("Date must be in YYJJJ format.")
    except (IOError, ValueError) as e:
        print(f"Error reading initial date: {e}", file=sys.stderr)
        sys.exit(1)

    idate = idate+"1200"

    # --- Setup output file path ---
    adate10 = adate_to_adate10(idate)
    json_filename = f"/home/caic/www/snowpack/json/nohrsc/{adate10[:6]}.json"

    # --- Set times for NOHRSC and wrf.
    time_sec = adate_to_time(idate)
    date_str = time_to_adate(time_sec)
    date = adate_to_wrfdate(date_str)
    nohrsc_time = date[0:10]+" 12:00"

# Connect to the snowpack database.

    conn = create_connection("localhost", "caic", "steepndeep", "snowpack")

# Retrieve NOHRSC HS data.

    print(f"Read NOHRSC HS at: {nohrsc_time}")
    query = "select snowDepth from snowAnal where wrfRes='2km' and analType='nohrsc' and time='"+nohrsc_time+"' and ptId in (select id from zones_2km) order by ptid"
    results = execute_read_query(conn, query)

    nsta = len(results)
    print(f"No. polygon points: {nsta}")  

    json_features = [];
    if results:
        for row in results:
            hs = row[0]/10
            json_feature = {
                "hs_nohrsc": hs,
            }
            json_features.append(json_feature)


# Close the db connection.

    if conn and conn.is_connected():
        conn.close()
#       print("MySQL connection is closed")

# Define and fill json data structure.
                
    json_data = {
        "type": "wrfGeom",
        "time" : nohrsc_time,
        "features" : json_features
    }

# Write the JSON data to a file.
# We use 'w' to open the file in write mode.
# The `json.dump()` function serializes the Python dictionary into a JSON formatted string.
# `indent=4` makes the file human-readable by pretty-printing it.
    try:
        with open(json_filename, 'w') as f:
#           json.dump(json_data, f, indent=4)
            json.dump(json_data, f, separators=(',', ':')) # No indent, compact separators
        print(f"json --> {json_filename}")

    except IOError as e:
        print(f"Error writing to file: {e}")

if __name__ == "__main__":
    main()
