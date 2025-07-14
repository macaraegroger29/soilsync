#!/usr/bin/env python3
"""
Rainfall Data Test Script
This script helps verify if rainfall data is real or random by testing both APIs.
"""

import requests
import json
from datetime import datetime

def test_backend_api():
    """Test the backend API for rainfall data"""
    print("=" * 50)
    print("TESTING BACKEND API")
    print("=" * 50)
    
    url = "http://192.168.254.174:8000/api/weather/"
    params = {
        'latitude': 14.5995,
        'longitude': 120.9842
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Rainfall: {data.get('rainfall', 'N/A')}")
            print(f"Source: {data.get('source', 'N/A')}")
        else:
            print("❌ Backend API failed")
            
    except Exception as e:
        print(f"❌ Backend API Error: {e}")

def test_openmeteo_api():
    """Test Open-Meteo API directly"""
    print("\n" + "=" * 50)
    print("TESTING OPEN-METEO API")
    print("=" * 50)
    
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        'latitude': 14.5995,
        'longitude': 120.9842,
        'current': 'precipitation',
        'timezone': 'auto'
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            current = data.get('current', {})
            print(f"Precipitation: {current.get('precipitation', 'N/A')}")
            print(f"Time: {current.get('time', 'N/A')}")
        else:
            print("❌ Open-Meteo API failed")
            
    except Exception as e:
        print(f"❌ Open-Meteo API Error: {e}")

def test_multiple_locations():
    """Test multiple locations to see if data varies"""
    print("\n" + "=" * 50)
    print("TESTING MULTIPLE LOCATIONS")
    print("=" * 50)
    
    locations = [
        {"name": "Manila", "lat": 14.5995, "lon": 120.9842},
        {"name": "Cebu", "lat": 10.3157, "lon": 123.8854},
        {"name": "Davao", "lat": 7.1907, "lon": 125.4553},
    ]
    
    for location in locations:
        print(f"\n📍 Testing {location['name']}:")
        
        # Test Open-Meteo for this location
        url = "https://api.open-meteo.com/v1/forecast"
        params = {
            'latitude': location['lat'],
            'longitude': location['lon'],
            'current': 'precipitation',
            'timezone': 'auto'
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            if response.status_code == 200:
                data = response.json()
                current = data.get('current', {})
                precipitation = current.get('precipitation', 'N/A')
                print(f"  Precipitation: {precipitation}")
            else:
                print(f"  ❌ Failed to get data")
        except Exception as e:
            print(f"  ❌ Error: {e}")

if __name__ == "__main__":
    print("🌧️  RAINFALL DATA VERIFICATION TOOL")
    print("This tool helps verify if rainfall data is real or random")
    print(f"Timestamp: {datetime.now()}")
    
    # Test both APIs
    test_backend_api()
    test_openmeteo_api()
    test_multiple_locations()
    
    print("\n" + "=" * 50)
    print("ANALYSIS:")
    print("=" * 50)
    print("✅ If you see different precipitation values for different locations,")
    print("   the data is likely real.")
    print("❌ If you see the same values everywhere, it might be random/mock data.")
    print("\n💡 Check the Flutter app logs for '🔍 Weather Service Debug' messages")
    print("   to see what data is being fetched in the app.") 