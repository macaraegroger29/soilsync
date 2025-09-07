#!/usr/bin/env python3
"""
Complete test script to verify the full registration and login flow
"""

import requests
import json
import time

# Configuration
BASE_URL = "http://localhost:8000"  # Adjust this to your server URL

def test_complete_flow():
    """Test the complete registration and login flow"""
    print("=== SoilSync Complete Flow Test ===\n")
    
    # Test data
    test_users = [
        {
            "username": "testuser3",
            "email": "testuser3@example.com",
            "password": "testpass123",
            "role": "user"
        },
        {
            "username": "testuser4", 
            "email": "testuser4@example.com",
            "password": "testpass123",
            "role": "admin"
        }
    ]
    
    for i, user_data in enumerate(test_users, 1):
        print(f"--- Testing User {i}: {user_data['username']} ---")
        
        # Step 1: Register user
        print("1. Registering user...")
        try:
            response = requests.post(
                f"{BASE_URL}/api/register/",
                headers={"Content-Type": "application/json"},
                json=user_data,
                timeout=10
            )
            
            if response.status_code in [200, 201]:
                print("✅ Registration successful!")
            else:
                print(f"❌ Registration failed: {response.status_code} - {response.text}")
                continue
                
        except Exception as e:
            print(f"❌ Registration error: {e}")
            continue
        
        # Step 2: Login with username
        print("2. Testing login with username...")
        try:
            login_data = {
                "username_or_email": user_data["username"],
                "password": user_data["password"]
            }
            
            response = requests.post(
                f"{BASE_URL}/api/token/",
                headers={"Content-Type": "application/json"},
                json=login_data,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                print("✅ Login with username successful!")
                print(f"   Role: {data.get('role', 'N/A')}")
                print(f"   Token: {data.get('access', 'N/A')[:50]}...")
            else:
                print(f"❌ Login with username failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"❌ Login with username error: {e}")
        
        # Step 3: Login with email
        print("3. Testing login with email...")
        try:
            login_data = {
                "username_or_email": user_data["email"],
                "password": user_data["password"]
            }
            
            response = requests.post(
                f"{BASE_URL}/api/token/",
                headers={"Content-Type": "application/json"},
                json=login_data,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                print("✅ Login with email successful!")
                print(f"   Role: {data.get('role', 'N/A')}")
                print(f"   Token: {data.get('access', 'N/A')[:50]}...")
            else:
                print(f"❌ Login with email failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"❌ Login with email error: {e}")
        
        # Step 4: Test invalid credentials
        print("4. Testing invalid credentials...")
        try:
            login_data = {
                "username_or_email": user_data["username"],
                "password": "wrongpassword"
            }
            
            response = requests.post(
                f"{BASE_URL}/api/token/",
                headers={"Content-Type": "application/json"},
                json=login_data,
                timeout=10
            )
            
            if response.status_code == 400:
                print("✅ Invalid password correctly rejected!")
            else:
                print(f"❌ Invalid password not properly handled: {response.status_code}")
                
        except Exception as e:
            print(f"❌ Invalid credentials test error: {e}")
        
        print(f"--- User {i} test complete ---\n")
        time.sleep(1)  # Small delay between users
    
    print("=== Complete Flow Test Finished ===")

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
    
    # Run complete flow test
    test_complete_flow()
