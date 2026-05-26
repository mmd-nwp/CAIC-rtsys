import requests
from datetime import datetime

def fetch_and_print_forecast(lat, lon, model):
    url = f"http://127.0.0.1:5000/point_forecast?model={model}&lat={lat}&lon={lon}"
    
    print(f"Fetching data from: {url}...\n")
    try:
        response = requests.get(url)
        response.raise_for_status()  # Check for HTTP errors
        data = response.json()
    except Exception as e:
        print(f"Error fetching or parsing data: {e}")
        return

    # Extract Metadata
    model_name = data.get('model', 'UNKNOWN')
    init_time = data.get('init_time', 'UNKNOWN')
    elevation = data.get('elevation', 'UNKNOWN')

    # Print Header Info
    print(f"MODEL: {model_name} | INIT: {init_time} | ELEVATION: {elevation} ft")
    print(f"LOCATION: {lat}, {lon}")
    print("=" * 105)
    
    # Define and print the column headers
    cols = ["Valid Time", "Temp", "Dew", "RH%", "Sky%", "WSpd", "WGst", "WDir", "Precip", "Snow", "AccPcp", "AccSnw"]
    header = f"{cols[0]:<15} | {cols[1]:>5} | {cols[2]:>5} | {cols[3]:>4} | {cols[4]:>4} | {cols[5]:>5} | {cols[6]:>5} | {cols[7]:>4} | {cols[8]:>6} | {cols[9]:>5} | {cols[10]:>6} | {cols[11]:>6}"
    print(header)
    print("-" * 105)

    # Helper function to format numbers and handle nulls safely
    def fmt(val, decimals=1):
        if val is None:
            return "---"
        # Format the number as a string with exact decimal places
        return f"{val:.{decimals}f}"

    # Extract all arrays
    times = data.get('times', [])
    temps = data.get('temperature', [])
    dews = data.get('dewpoint', [])
    rhs = data.get('rh', [])
    skys = data.get('sky', [])
    wspds = data.get('wind_speed', [])
    wgusts = data.get('wind_gust', [])
    wdirs = data.get('wind_dir', [])
    precips = data.get('precip', [])
    snows = data.get('snow', [])
    acc_precips = data.get('accum_precip', [])
    acc_snows = data.get('accum_snow', [])

    # Loop through the timeline and print each row
    for i in range(len(times)):
        # Format the ISO timestamp into something cleaner (e.g., 05/04 12:00)
        try:
            dt = datetime.fromisoformat(times[i])
            time_str = dt.strftime("%m/%d %H:%M")
        except:
            time_str = str(times[i])

        # Safely pull the values using the index
        t   = fmt(temps[i] if i < len(temps) else None, 1)
        d   = fmt(dews[i] if i < len(dews) else None, 1)
        rh  = fmt(rhs[i] if i < len(rhs) else None, 0)
        sky = fmt(skys[i] if i < len(skys) else None, 0)
        ws  = fmt(wspds[i] if i < len(wspds) else None, 1)
        wg  = fmt(wgusts[i] if i < len(wgusts) else None, 1)
        wd  = fmt(wdirs[i] if i < len(wdirs) else None, 0)
        pcp = fmt(precips[i] if i < len(precips) else None, 3)
        snw = fmt(snows[i] if i < len(snows) else None, 2)
        apc = fmt(acc_precips[i] if i < len(acc_precips) else None, 3)
        asn = fmt(acc_snows[i] if i < len(acc_snows) else None, 2)

        # Construct and print the perfectly aligned row
        row = f"{time_str:<15} | {t:>5} | {d:>5} | {rh:>4} | {sky:>4} | {ws:>5} | {wg:>5} | {wd:>4} | {pcp:>6} | {snw:>5} | {apc:>6} | {asn:>6}"
        print(row)

if __name__ == '__main__':
    # You can change these parameters to test different locations/models
    fetch_and_print_forecast(lat=40.51, lon=-105.89, model="nbm")
