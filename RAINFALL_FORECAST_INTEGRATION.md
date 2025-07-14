# Rainfall Forecast Integration for SoilSync

## Overview

This document describes the real-time rainfall forecast integration implemented for the SoilSync application. The integration provides real-time weather data for the rainfall field sensor mode, replacing mock data with actual weather information.

## Features

### 1. Real-Time Weather Data
- **Current Weather**: Temperature, humidity, and rainfall data from Open-Meteo API
- **Location-Based**: Uses device GPS or manual coordinates
- **7-Day Forecast**: Extended rainfall and weather predictions
- **Weather Icons**: Visual representation of weather conditions

### 2. Flutter Frontend Integration

#### Weather Service (`lib/services/weather_service.dart`)
- **API Integration**: Connects to Open-Meteo API (free, no API key required)
- **Backend Fallback**: Uses Django backend as primary, direct API as fallback
- **Location Services**: Automatic GPS location detection
- **Caching**: 30-minute cache for weather data to reduce API calls
- **Error Handling**: Graceful fallback to mock data if APIs fail

#### Rainfall Forecast Widget (`lib/widgets/rainfall_forecast_widget.dart`)
- **Expandable UI**: Collapsible forecast display
- **Current Weather**: Real-time temperature, humidity, and rainfall
- **7-Day Forecast**: Daily weather predictions with rainfall amounts
- **Weather Icons**: Emoji-based weather representation
- **Error States**: User-friendly error messages and retry functionality

#### User Dashboard Integration
- **Sensor Mode**: Real weather data replaces mock values
- **Automatic Updates**: Weather data refreshes every 30 seconds in sensor mode
- **Fallback System**: Uses mock data if weather service fails

### 3. Django Backend Integration

#### Weather API Endpoint (`soilsync_backend/api/views.py`)
- **Route**: `/api/weather/?lat={latitude}&lon={longitude}`
- **Open-Meteo Integration**: Fetches weather data from Open-Meteo API
- **Data Parsing**: Extracts current weather and forecast data
- **Error Handling**: Comprehensive error handling and logging

#### API Response Format
```json
{
  "current_weather": {
    "temperature": 25.0,
    "humidity": 60.0,
    "rainfall": 0.0,
    "weather_code": 0,
    "latitude": 14.5995,
    "longitude": 120.9842,
    "timestamp": "2024-01-01T12:00:00Z"
  },
  "hourly_rainfall": [0.0, 0.0, ...],
  "forecast": [
    {
      "date": "2024-01-01",
      "rainfall": 0.0,
      "temperature_max": 25.0,
      "temperature_min": 20.0,
      "weather_code": 0
    }
  ]
}
```

## Installation & Setup

### 1. Flutter Dependencies
Add the following to `pubspec.yaml`:
```yaml
dependencies:
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  intl: ^0.19.0
  weather: ^3.1.1
  weather_icons: ^3.0.0
```

### 2. Android Permissions
Add location permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 3. Django Dependencies
Add to `soilsync_backend/requirements.txt`:
```
requests==2.31.0
```

## Usage

### 1. Sensor Mode Integration
When the app is in automatic sensor mode:
1. Weather service fetches real-time weather data
2. Temperature, humidity, and rainfall values are updated automatically
3. Soil parameters (N, P, K, pH) remain as mock data (from actual sensors in production)
4. Predictions are made using real environmental data

### 2. Manual Mode
- Users can still input values manually
- Rainfall forecast widget provides weather context
- Real-time weather data available for reference

### 3. Weather Widget Features
- **Current Conditions**: Real-time temperature, humidity, rainfall
- **Weather Description**: Human-readable weather conditions
- **7-Day Forecast**: Expandable forecast with daily predictions
- **Location-Based**: Uses device GPS for accurate local weather
- **Refresh Capability**: Manual refresh button for latest data

## API Integration

### Open-Meteo API (Primary)
- **URL**: `https://api.open-meteo.com/v1/forecast`
- **Free**: No API key required
- **Features**: Current weather, hourly forecasts, daily forecasts
- **Rate Limits**: Generous limits for free tier

### Django Backend API (Fallback)
- **URL**: `{base_url}/api/weather/?lat={latitude}&lon={longitude}`
- **Purpose**: Centralized weather data management
- **Caching**: Reduces API calls to external services
- **Error Handling**: Graceful degradation

## Error Handling

### 1. Location Services
- **GPS Disabled**: Shows error message with retry option
- **Permission Denied**: Requests location permissions
- **Network Issues**: Falls back to cached data or mock values

### 2. API Failures
- **Backend Unavailable**: Falls back to direct Open-Meteo API
- **Weather API Down**: Uses cached data or mock values
- **Network Timeout**: Graceful timeout handling

### 3. Data Validation
- **Invalid Coordinates**: Uses default Manila coordinates
- **Missing Data**: Provides sensible defaults
- **API Errors**: Logs errors and shows user-friendly messages

## Weather Codes

The system uses WMO (World Meteorological Organization) weather codes:

| Code | Description | Icon |
|------|-------------|------|
| 0 | Clear sky | ☀️ |
| 1-3 | Partly cloudy | 🌤️ |
| 45,48 | Foggy | 🌫️ |
| 51-55 | Light drizzle | 🌧️ |
| 61-65 | Rain | 🌧️ |
| 71-75 | Snow | ❄️ |
| 80-82 | Rain showers | 🌦️ |
| 95 | Thunderstorm | ⛈️ |

## Performance Considerations

### 1. Caching Strategy
- **Weather Data**: 30-minute cache to reduce API calls
- **Location Data**: Cached to avoid repeated GPS requests
- **Fallback Data**: Mock data available offline

### 2. API Optimization
- **Batch Requests**: Single API call for current + forecast data
- **Error Recovery**: Automatic retry with exponential backoff
- **Rate Limiting**: Respects API rate limits

### 3. Battery Optimization
- **Location Services**: Only when needed
- **Background Updates**: Minimal background processing
- **Efficient Polling**: 30-second intervals in sensor mode

## Future Enhancements

### 1. Advanced Weather Features
- **Weather Alerts**: Severe weather notifications
- **Historical Data**: Past weather patterns
- **Weather Maps**: Visual weather representation

### 2. Sensor Integration
- **Real Soil Sensors**: Replace mock soil data
- **IoT Integration**: Direct sensor communication
- **Data Validation**: Cross-reference sensor and weather data

### 3. Machine Learning
- **Weather Impact**: Analyze weather effects on crop predictions
- **Pattern Recognition**: Identify weather-crop correlations
- **Predictive Analytics**: Weather-based crop recommendations

## Troubleshooting

### Common Issues

1. **Location Permission Denied**
   - Solution: Grant location permissions in app settings
   - Fallback: Use default coordinates (Manila)

2. **Weather Data Not Loading**
   - Check internet connection
   - Verify API endpoints are accessible
   - Check app logs for error details

3. **GPS Not Working**
   - Enable location services on device
   - Check app permissions
   - Try refreshing weather data

### Debug Information

Enable debug logging by checking console output for:
- Weather API responses
- Location service status
- Cache hit/miss information
- Error details and stack traces

## Security Considerations

1. **Location Privacy**: GPS data is only used for weather requests
2. **API Security**: No sensitive data sent to weather APIs
3. **Data Storage**: Weather data cached locally only
4. **Network Security**: HTTPS connections to all APIs

## Testing

### Manual Testing
1. Enable sensor mode in the app
2. Verify weather data appears in rainfall field
3. Check forecast widget displays correctly
4. Test location permission scenarios
5. Verify fallback behavior with network issues

### Automated Testing
- Unit tests for weather service
- Integration tests for API endpoints
- UI tests for weather widget
- Error handling tests

## Support

For issues related to the rainfall forecast integration:
1. Check the console logs for error messages
2. Verify network connectivity
3. Test with different locations
4. Review API documentation for changes

---

**Note**: This integration uses the free Open-Meteo API. For production use with high traffic, consider upgrading to a paid weather API service or implementing additional caching strategies. 