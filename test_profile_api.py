#!/usr/bin/env python3
import requests
import json

# Test the user profile API endpoint
def test_profile_api():
    base_url = "http://localhost:8000"
    
    # First, let's try to get a token by logging in
    login_data = {
        "username_or_email": "dhea",  # Use the username you mentioned
        "password": "your_password_here"  # You'll need to provide the actual password
    }
    
    try:
        # Try to get a token
        login_response = requests.post(
            f"{base_url}/api/token/",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Login response status: {login_response.status_code}")
        print(f"Login response: {login_response.text}")
        
        if login_response.status_code == 200:
            token_data = login_response.json()
            access_token = token_data.get('access')
            
            if access_token:
                # Now test the profile endpoint
                profile_response = requests.get(
                    f"{base_url}/api/user/profile/",
                    headers={
                        "Authorization": f"Bearer {access_token}",
                        "Content-Type": "application/json"
                    }
                )
                
                print(f"\nProfile response status: {profile_response.status_code}")
                print(f"Profile response: {profile_response.text}")
                
                if profile_response.status_code == 200:
                    profile_data = profile_response.json()
                    print(f"\nUsername: {profile_data.get('username')}")
                    print(f"Email: {profile_data.get('email')}")
                    print(f"Role: {profile_data.get('role')}")
                else:
                    print(f"Profile API failed: {profile_response.status_code}")
            else:
                print("No access token received")
        else:
            print(f"Login failed: {login_response.status_code}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_profile_api()
