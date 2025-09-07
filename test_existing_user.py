#!/usr/bin/env python3
"""
Test script to verify login with existing user
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:8000"  # Adjust this to your server URL

def test_existing_user_login():
    """Test login with existing user"""
    print("=== Testing Login with Existing User ===\n")
    
    # Test with user 'carl' (ID: 16, email: carlivan@gmail.com)
    test_cases = [
        {
            "username_or_email": "carl",
            "password": "carlivan123",
            "description": "Login with username 'carl'"
        },
        {
            "username_or_email": "carlivan@gmail.com",
            "password": "carlivan123",
            "description": "Login with email 'carlivan@gmail.com'"
        },
        {
            "username_or_email": "testroger",
            "password": "roger123",
            "description": "Login with username 'testroger'"
        },
        {
            "username_or_email": "roger@gmail.com",
            "password": "roger123",
            "description": "Login with email 'roger@gmail.com'"
        }
    ]
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"Test {i}: {test_case['description']}")
        
        try:
            response = requests.post(
                f"{BASE_URL}/api/token/",
                headers={"Content-Type": "application/json"},
                json={
                    "username_or_email": test_case["username_or_email"],
                    "password": test_case["password"]
                },
                timeout=10
            )
            
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.text}")
            
            if response.status_code == 200:
                data = response.json()
                print("✅ Login successful!")
                print(f"   Role: {data.get('role', 'N/A')}")
                print(f"   Token: {data.get('access', 'N/A')[:50]}...")
            else:
                print("❌ Login failed!")
                
        except Exception as e:
            print(f"❌ Error: {e}")
        
        print()

def test_server_status():
    """Test if server is running"""
    print("Testing server status...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/", timeout=5)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            print("✅ Server is running!")
            return True
        else:
            print("❌ Server is not responding correctly!")
            return False
            
    except Exception as e:
        print(f"❌ Server is not accessible: {e}")
        return False

if __name__ == "__main__":
    # First check if server is running
    if not test_server_status():
        print("\n❌ Cannot proceed with tests - server is not accessible!")
        exit(1)
    
    # Test existing user login
    test_existing_user_login()
