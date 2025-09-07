#!/usr/bin/env python3
"""
Test script to verify login functionality with username and email
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:8000"  # Adjust this to your server URL

def test_login_with_username():
    """Test login with username"""
    print("Testing login with username...")
    
    login_data = {
        "username_or_email": "testuser2",
        "password": "testpass123"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/token/",
            headers={"Content-Type": "application/json"},
            json=login_data,
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Login with username successful!")
            print(f"Access Token: {data.get('access', 'N/A')[:50]}...")
            print(f"Role: {data.get('role', 'N/A')}")
        else:
            print("❌ Login with username failed!")
            
    except Exception as e:
        print(f"❌ Error testing username login: {e}")

def test_login_with_email():
    """Test login with email"""
    print("\nTesting login with email...")
    
    login_data = {
        "username_or_email": "testuser2@example.com",
        "password": "testpass123"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/token/",
            headers={"Content-Type": "application/json"},
            json=login_data,
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Login with email successful!")
            print(f"Access Token: {data.get('access', 'N/A')[:50]}...")
            print(f"Role: {data.get('role', 'N/A')}")
        else:
            print("❌ Login with email failed!")
            
    except Exception as e:
        print(f"❌ Error testing email login: {e}")

def test_registration():
    """Test user registration"""
    print("\nTesting user registration...")
    
    register_data = {
        "username": "testuser2",
        "email": "testuser2@example.com",
        "password": "testpass123",
        "role": "user"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/register/",
            headers={"Content-Type": "application/json"},
            json=register_data,
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code in [200, 201]:
            print("✅ Registration successful!")
        else:
            print("❌ Registration failed!")
            
    except Exception as e:
        print(f"❌ Error testing registration: {e}")

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
    print("=== SoilSync Login API Test ===\n")
    
    # First check if server is running
    if not test_server_status():
        print("\n❌ Cannot proceed with tests - server is not accessible!")
        exit(1)
    
    # Test registration first
    test_registration()
    
    # Test login with username
    test_login_with_username()
    
    # Test login with email
    test_login_with_email()
    
    print("\n=== Test Complete ===")
