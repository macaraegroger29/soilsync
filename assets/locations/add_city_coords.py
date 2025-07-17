import json
import requests
import time

INPUT_JSON = r"C:\Users\jao\projects\soilsync\assets\locations\philippine_provinces_cities_municipalities_and_barangays_2019v2.json"
OUTPUT_JSON = r"C:\Users\jao\projects\soilsync\assets\locations\philippine_provinces_cities_municipalities_and_barangays_2019v2_with_coords.json"
USER_AGENT = "SoilSyncCoordinateScript/1.0 (22BGU1224_ms@psu.edu.ph)"  # Change to your email

def get_coords(city, province, region):
    """Query Nominatim for coordinates."""
    query = f"{city}, {province}, {region}, Philippines"
    url = "https://nominatim.openstreetmap.org/search"
    params = {
        "q": query,
        "format": "json",
        "limit": 1,
        "addressdetails": 0,
    }
    headers = {"User-Agent": USER_AGENT}
    try:
        resp = requests.get(url, params=params, headers=headers, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        if data:
            return float(data[0]["lat"]), float(data[0]["lon"])
    except Exception as e:
        print(f"Error for {query}: {e}")
    return None, None

def main():
    with open(INPUT_JSON, encoding="utf-8") as f:
        data = json.load(f)

    for region_code, region in data.items():
        region_name = region.get("region_name", "")
        for province_name, province in region["province_list"].items():
            for city_name, city in province["municipality_list"].items():
                # Only add if not already present
                if "lat" not in city or "lon" not in city:
                    print(f"Fetching: {city_name}, {province_name}, {region_name}")
                    lat, lon = get_coords(city_name, province_name, region_name)
                    if lat and lon:
                        city["lat"] = lat
                        city["lon"] = lon
                        print(f"  -> {lat}, {lon}")
                    else:
                        print("  -> Not found")
                    time.sleep(1)  # Be nice to the API

    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Done! Output written to {OUTPUT_JSON}")

if __name__ == "__main__":
    main()