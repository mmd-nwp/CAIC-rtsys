import json

# Your JSON data
json_string = """ {"STATION":[{"ID":"285375","STID":"046ID","NAME":"W3T13","ELEVATION":"4777.0","LATITUDE":"44.96370","LONGITUDE":"-115.49268","STATUS":"ACTIVE","MNET_ID":"317","STATE":"ID","COUNTRY":"US","TIMEZONE":"America\/Boise","ELEV_DEM":null,"PERIOD_OF_RECORD":{"start":"2025-06-06T14:30:00Z","end":"2026-01-23T15:40:00Z"},"UNITS":{"position":"m","elevation":"ft"},"SENSOR_VARIABLES":{"air_temp":{"air_temp_set_1":{}},"relative_humidity":{"relative_humidity_set_1":{}},"wind_speed":{"wind_speed_set_1":{}},"wind_direction":{"wind_direction_set_1":{}},"wind_gust":{"wind_gust_set_1":{}},"dew_point_temperature":{"dew_point_temperature_set_1d":{"derived_from":["air_temp_set_1","relative_humidity_set_1"]}}},"OBSERVATIONS":{"date_time":["2026-01-23T15:00:00Z","2026-01-23T15:10:00Z","2026-01-23T15:20:00Z","2026-01-23T15:30:00Z","2026-01-23T15:40:00Z","2026-01-23T15:50:00Z"],"air_temp_set_1":[-9.622,-9.761,-9.983,-10.028,-10.333,-10.356],"relative_humidity_set_1":[85.4,85.3,86.2,86.7,87.2,87.6],"wind_speed_set_1":[0.252,0.139,0.087,0.01,0.01,0.329],"wind_direction_set_1":[45.79,65.37,48.5,74.19,58.37,30.17],"wind_gust_set_1":[0.586,0.556,0.329,0.293,0.293,0.586],"dew_point_temperature_set_1d":[-11.64,-11.79,-11.88,-11.85,-12.08,-12.04]},"QC_FLAGGED":false,"RESTRICTED":false,"RESTRICTED_METADATA":false},{"ID":"317950","STID":"IDP02","NAME":"SnowBank PG","ELEVATION":"8297.0","LATITUDE":"44.44033","LONGITUDE":"-116.12623","STATUS":"ACTIVE","MNET_ID":"330","STATE":"ID","COUNTRY":"US","TIMEZONE":"America\/Boise","ELEV_DEM":null,"PERIOD_OF_RECORD":{"start":"2025-09-26T10:17:00Z","end":"2026-01-23T15:33:00Z"},"UNITS":{"position":"m","elevation":"ft"},"SENSOR_VARIABLES":{"relative_humidity":{"relative_humidity_set_1":{}},"air_temp":{"air_temp_set_1":{}},"wind_speed":{"wind_speed_set_1":{}},"wind_direction":{"wind_direction_set_1":{}},"dew_point_temperature":{"dew_point_temperature_set_1d":{"derived_from":["air_temp_set_1","relative_humidity_set_1"]}}},"OBSERVATIONS":{"date_time":["2026-01-23T14:58:00Z","2026-01-23T15:03:00Z","2026-01-23T15:13:00Z","2026-01-23T15:18:00Z","2026-01-23T15:23:00Z","2026-01-23T15:33:00Z","2026-01-23T15:43:00Z","2026-01-23T15:48:00Z"],"relative_humidity_set_1":[38.0,38.0,36.0,38.0,39.0,39.0,37.0,37.0],"air_temp_set_1":[-7.0,-7.0,-7.0,-7.0,-7.0,-8.0,-7.0,-8.0],"wind_speed_set_1":[9.34,10.17,9.17,7.78,7.47,6.87,6.65,7.04],"wind_direction_set_1":[353.0,357.0,12.0,15.0,22.0,34.0,40.0,29.0],"dew_point_temperature_set_1d":[-19.04,-19.04,-19.67,-19.04,-18.74,-19.64,-19.35,-20.25]},"QC_FLAGGED":false,"RESTRICTED":false,"RESTRICTED_METADATA":false}],"SUMMARY":{"NUMBER_OF_OBJECTS":2,"RESPONSE_CODE":1,"RESPONSE_MESSAGE":"OK","METADATA_QUERY_TIME":"2.5 ms","METADATA_PARSE_TIME":"0.2 ms","TOTAL_METADATA_TIME":"2.7 ms","DATA_QUERY_TIME":"2.6 ms","QC_QUERY_TIME":"2.9 ms","DATA_PARSE_TIME":"0.6 ms","TOTAL_DATA_TIME":"6.0 ms","TOTAL_TIME":"8.7 ms","VERSION":"v2.30.4"},"QC_SUMMARY":{"QC_CHECKS_APPLIED":["sl_range_check"],"TOTAL_OBSERVATIONS_FLAGGED":0,"PERCENT_OF_TOTAL_OBSERVATIONS_FLAGGED":0.0},"UNITS":{"position":"m","elevation":"ft","air_temp":"Celsius","relative_humidity":"%","wind_speed":"m\/s","wind_direction":"Degrees","wind_gust":"m\/s","dew_point_temperature":"Celsius"}} """
data = json.loads(json_string)

# Header for the output
header = f"{'Station':<15} | {'Date/Time':<20} | {'Temp':<7} | {'Dewp':<7} | {'Humidity':<5} | {'Wind':<8} | {'Direction':<8} | {'Gust'}"
print(header)
print("-" * len(header))

for station in data['STATION']:
    station_name = station['NAME']
    obs = station.get('OBSERVATIONS', {})
    
    # Extract the lists
    times = obs.get('date_time', [])
    temps = obs.get('air_temp_set_1', [])
    dewps = obs.get('dew_point_temperature_set_1d', [])
    humidities = obs.get('relative_humidity_set_1', [])
    winds = obs.get('wind_speed_set_1', [])
    wdirs = obs.get('wind_direction_set_1', [])
    gusts = obs.get('wind_gust_set_1', [])

    # Use zip to loop through the parallel lists together
    for t, temp, dewp, hum, wind, wdir in zip(times, temps, dewps, humidities, winds, wdirs):
        # Format the timestamp for better readability
        clean_time = t.replace('T', ' ').replace('Z', '')
        
        print(f"{station_name:<15} | {clean_time:<20} | {temp:<7} | {dewp:<7} |{hum:<8} | {wind:<8} | {wdir:<8}")
    
    # Visual break between different stations
    print("-" * len(header))
