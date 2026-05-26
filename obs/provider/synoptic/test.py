import json

# The JSON data provided
json_data = """
{
  "STATION": [
    {
      "ID": "285375",
      "STID": "046ID",
      "NAME": "W3T13",
      "OBSERVATIONS": {
        "air_temp_value_1": {"value": -9.761, "date_time": "2026-01-23T15:10:00Z"},
        "relative_humidity_value_1": {"value": 85.3, "date_time": "2026-01-23T15:10:00Z"},
        "wind_speed_value_1": {"value": 0.139, "date_time": "2026-01-23T15:10:00Z"}
      }
    },
    {
      "ID": "317950",
      "STID": "IDP02",
      "NAME": "SnowBank PG",
      "OBSERVATIONS": {
        "air_temp_value_1": {"value": -7.0, "date_time": "2026-01-23T15:03:00Z"},
        "relative_humidity_value_1": {"value": 38.0, "date_time": "2026-01-23T15:03:00Z"},
        "wind_speed_value_1": {"value": 10.17, "date_time": "2026-01-23T15:03:00Z"}
      }
    }
  ],
  "UNITS": {
    "air_temp": "Celsius",
    "wind_speed": "m/s"
  }
}
"""

# 1. Parse the JSON string into a dictionary
data = json.loads(json_data)

# 2. Get the global units for reference
units = data.get("UNITS", {})

print(f"{'Station Name':<15} | {'Temp':<8} | {'Humidity':<8} | {'Wind Speed'}")
print("-" * 55)

# 3. Iterate through each station
for station in data['STATION']:
    name = station['NAME']
    obs = station.get('OBSERVATIONS', {})
    
    # Safely extract values using .get() to avoid errors if a value is missing
    temp = obs.get('air_temp_value_1', {}).get('value', 'N/A')
    humidity = obs.get('relative_humidity_value_1', {}).get('value', 'N/A')
    wind = obs.get('wind_speed_value_1', {}).get('value', 'N/A')
    
    print(f"{name:<15} | {temp:<8} | {humidity:<8} | {wind}")

# 4. Example of accessing metadata
print(f"\nTotal Stations Processed: {len(data['STATION'])}")
