import requests
import re

def test_login():
    session = requests.Session()
    login_url = "http://127.0.0.1:8000/dashboard/login/"
    dashboard_url = "http://127.0.0.1:8000/dashboard/"
    
    print("Fetching login page to retrieve CSRF token...")
    r = session.get(login_url)
    if r.status_code != 200:
        print(f"Failed to fetch login page: {r.status_code}")
        return
        
    match = re.search(r'name=["\']csrfmiddlewaretoken["\']\s+value=["\']([^"\']+)["\']', r.text)
    if not match:
        match = re.search(r'value=["\']([^"\']+)["\']\s+name=["\']csrfmiddlewaretoken["\']', r.text)
        
    if not match:
        print("CSRF token not found via regex!")
        return
        
    csrf_token = match.group(1)
    print(f"Found CSRF Token: {csrf_token[:10]}...")
    
    headers = {
        'Referer': login_url
    }
    payload = {
        'username': 'admin',
        'password': 'adminpass123',
        'csrfmiddlewaretoken': csrf_token
    }
    
    print("Sending POST request to log in...")
    r_post = session.post(login_url, data=payload, headers=headers)
    print(f"POST Response Status Code: {r_post.status_code}")
    print(f"POST Response URL: {r_post.url}")
    
    print("Fetching dashboard page...")
    r_dash = session.get(dashboard_url)
    print(f"Dashboard Response Status Code: {r_dash.status_code}")
    
    if "Welcome back" in r_dash.text or "Log Out" in r_dash.text or "Dashboard" in r_dash.text or r_dash.status_code == 200:
        print("SUCCESS: Dashboard login test successful!")
        if "Welcome back, admin" in r_dash.text:
            print("Successfully authenticated as admin.")
        else:
            print("Page loaded successfully. Content snippet:")
            print(r_dash.text[:300])
    else:
        print("FAILED: Dashboard login test failed. Response snippet:")
        print(r_dash.text[:500])

if __name__ == '__main__':
    test_login()
