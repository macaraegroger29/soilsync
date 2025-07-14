#!/usr/bin/env python3
"""
Location Service Test Script
This script helps test the location settings functionality.
"""

import json
import requests
from datetime import datetime

def test_location_settings():
    """Test different locations for rainfall data"""
    print("=" * 50)
    print("LOCATION SETTINGS TEST")
    print("=" * 50)
    
    # Test different Philippine cities
    locations = [
        {"name": "Manila", "lat": 14.5995, "lon": 120.9842},
        {"name": "Cebu", "lat": 10.3157, "lon": 123.8854},
        {"name": "Davao", "lat": 7.1907, "lon": 125.4553},
        {"name": "Baguio", "lat": 16.4023, "lon": 120.5960},
        {"name": "Iloilo", "lat": 10.7203, "lon": 122.5621},
    ]
    
    print("Testing rainfall data for different locations:\n")
    
    for location in locations:
        print(f"📍 {location['name']}:")
        
        # Test backend API
        try:
            backend_url = f"http://192.168.254.174:8000/api/weather/?lat={location['lat']}&lon={location['lon']}"
            response = requests.get(backend_url, timeout=10)
            
            if response.statusCode == 200:
                data = response.json()
                rainfall = data.get('rainfall', 'N/A')
                print(f"  Backend API: {rainfall} mm")
            else:
                print(f"  Backend API: Failed ({response.statusCode})")
        except Exception as e:
            print(f"  Backend API: Error - {e}")
        
        # Test Open-Meteo API
        try:
            openmeteo_url = f"https://api.open-meteo.com/v1/forecast?latitude={location['lat']}&longitude={location['lon']}&current=precipitation&timezone=auto"
            response = requests.get(openmeteo_url, timeout=10)
            
            if response.statusCode == 200:
                data = response.json()
                precipitation = data['current']['precipitation']
                print(f"  Open-Meteo API: {precipitation} mm")
            else:
                print(f"  Open-Meteo API: Failed ({response.statusCode})")
        except Exception as e:
            print(f"  Open-Meteo API: Error - {e}")
        
        print()

def test_location_storage():
    """Test location storage simulation"""
    print("=" * 50)
    print("LOCATION STORAGE TEST")
    print("=" * 50)
    
    # Simulate location storage
    test_locations = [
        {"name": "User's Farm", "lat": 14.5995, "lon": 120.9842},
        {"name": "Test Location", "lat": 10.3157, "lon": 123.8854},
    ]
    
    for location in test_locations:
        print(f"📍 Testing {location['name']}:")
        print(f"  Coordinates: {location['lat']}, {location['lon']}")
        
        # Test API with these coordinates
        try:
            url = f"https://api.open-meteo.com/v1/forecast?latitude={location['lat']}&longitude={location['lon']}&current=precipitation&timezone=auto"
            response = requests.get(url, timeout=10)
            
            if response.statusCode == 200:
                data = response.json()
                precipitation = data['current']['precipitation']
                time = data['current']['time']
                print(f"  Rainfall: {precipitation} mm")
                print(f"  Time: {time}")
            else:
                print(f"  API Error: {response.statusCode}")
        except Exception as e:
            print(f"  Error: {e}")
        
        print()

if __name__ == "__main__":
    print("📍 LOCATION SERVICE VERIFICATION TOOL")
    print("This tool helps test location-based rainfall data")
    print(f"Timestamp: {datetime.now()}")
    
    test_location_settings()
    test_location_storage()
    
    print("=" * 50)
    print("INSTRUCTIONS:")
    print("=" * 50)
    print("1. Add LocationSettingsWidget to your settings page")
    print("2. Users can set their farm location")
    print("3. Weather service will use saved location")
    print("4. Test with different coordinates to verify")
    print("\n💡 The location service prioritizes:")
    print("   - Saved location from settings")
    print("   - Device GPS location")
    print("   - Default location (Manila)") 