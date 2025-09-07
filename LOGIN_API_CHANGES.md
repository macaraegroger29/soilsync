# Login API Changes - Username or Email Login

## Overview
The login API has been updated to allow users to login using either their username or email address. This provides more flexibility for users and improves the user experience.

## Changes Made

### Backend Changes (Django)

#### 1. Created Custom Authentication Backend in `soilsync_backend/api/authentication.py`

- **New File**: Created `UsernameOrEmailBackend` class that extends Django's `ModelBackend`
- **Authentication Logic**: Added logic to first try finding a user by username, then by email if username lookup fails
- **Integration**: Added the custom backend to Django settings

#### 2. Modified `CustomTokenObtainPairView` in `soilsync_backend/api/views.py`

- **Complete Rewrite**: Replaced the JWT serializer approach with a custom APIView
- **Field Handling**: Added support for `username_or_email` field in the request
- **Token Generation**: Manual JWT token generation with role information
- **Error Handling**: Comprehensive error handling for various scenarios

### Frontend Changes (Flutter)

#### 1. Updated `lib/login_screen.dart`

- **API Request**: Changed the request body to use `username_or_email` instead of `username`
- **UI Labels**: Updated form labels and validation messages to indicate users can use username or email
- **Error Messages**: Updated error messages to reflect the new capability

#### 2. Updated `lib/screens/enhanced_login_screen.dart`

- **API Request**: Changed the request body to use `username_or_email` instead of `username`
- **UI Labels**: Updated form labels and validation messages to indicate users can use username or email
- **Error Messages**: Updated error messages to reflect the new capability
- **Logging**: Updated debug logging to reflect the new field name

## API Endpoint

### Login Endpoint
- **URL**: `/api/token/`
- **Method**: `POST`
- **Content-Type**: `application/json`

### Request Body
```json
{
    "username_or_email": "user@example.com",  // or "username"
    "password": "userpassword"
}
```

### Response (Success - 200)
```json
{
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "role": "user"
}
```

### Response (Error - 400)
```json
{
    "detail": "No user found with this username or email."
}
```

## How It Works

1. **User Input**: User enters either their username or email in the login field
2. **Backend Processing**: 
   - First attempts to find user by username
   - If not found, attempts to find user by email
   - If neither found, returns error
3. **Authentication**: Uses Django's built-in authentication with the found user's username
4. **Token Generation**: Generates JWT tokens with user role information

## Testing

A test script `test_login_api.py` has been created to verify the functionality:

```bash
python test_login_api.py
```

This script will:
1. Test server connectivity
2. Register a test user
3. Test login with username
4. Test login with email

## Benefits

1. **User Flexibility**: Users can login with either username or email
2. **Better UX**: Reduces login friction, especially for users who might forget their username
3. **Backward Compatibility**: Existing username-based logins continue to work
4. **Security**: Maintains the same security standards as before

## Notes

- Registration still requires both username and email
- The system maintains unique constraints on both username and email
- Password validation and security remain unchanged
- Role-based access control continues to work as before

## Migration

No database migration is required as this is purely an API-level change. Existing users can immediately start using either their username or email to login.
