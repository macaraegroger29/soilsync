# Location Settings Integration Guide

## ✅ Precise Location Input is Already Available

The `LocationSettingsWidget` includes precise latitude and longitude input fields with the following features:

### 📍 Manual Coordinate Input
- **Latitude Field**: Accepts values from -90 to 90
- **Longitude Field**: Accepts values from -180 to 180
- **Input Validation**: Prevents invalid coordinates
- **Decimal Support**: Allows precise decimal coordinates
- **Auto-formatting**: Formats input for better readability

### 🎯 Quick Location Buttons
- Manila (14.5995, 120.9842)
- Cebu (10.3157, 123.8854)
- Davao (7.1907, 125.4553)
- Baguio (16.4023, 120.5960)
- Iloilo (10.7203, 122.5621)
- Zamboanga (6.9214, 122.0790)

### 📱 GPS Integration
- **Use GPS**: Gets current device location
- **Save Location**: Stores coordinates in app settings
- **Clear Location**: Removes saved coordinates

## 🔧 How to Add to Your Settings Page

### Option 1: Add as a New Section

Add this to your settings page:

```dart
// In your settings page build method
Widget _buildLocationSection() {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ListTile(
      leading: const Icon(Icons.location_on, color: Colors.blue),
      title: const Text('Location Settings'),
      subtitle: const Text('Set precise location for rainfall data'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LocationSettingsWidget(),
          ),
        );
      },
    ),
  );
}

// Add this to your settings page body
_buildLocationSection(),
```

### Option 2: Add as a Menu Item

Add this to your settings menu:

```dart
ListTile(
  leading: const Icon(Icons.location_on, color: Colors.blue),
  title: const Text('Location Settings'),
  subtitle: const Text('Set farm location for rainfall data'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationSettingsWidget(),
      ),
    );
  },
),
```

## 🎯 How It Works

1. **User opens Location Settings**
2. **User can:**
   - Enter precise latitude/longitude manually
   - Use GPS to get current location
   - Select from quick location buttons
   - Save the location to app settings
3. **Weather service uses saved location** for rainfall data
4. **If no location is saved**, falls back to device GPS or default location

## 📊 Example Usage

```dart
// User sets their farm location
Latitude: 14.5995
Longitude: 120.9842

// Weather service uses these coordinates
// Rainfall data is fetched for this exact location
```

## 🔍 Testing

You can test the location settings by:

1. **Opening the Location Settings widget**
2. **Entering different coordinates**
3. **Checking the rainfall data changes**
4. **Verifying the data is location-specific**

## 💡 Benefits

- **Precise Control**: Users can set exact farm coordinates
- **Consistent Data**: Same location used for all weather data
- **Offline Support**: Location saved in app settings
- **GPS Fallback**: Uses device location if no custom location set
- **Quick Access**: Pre-defined locations for common areas

The precise location input is already fully implemented and ready to use! 