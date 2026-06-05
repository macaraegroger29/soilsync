# SoilSync: User Manual & Guided Tour
*A Simple, Beginner-Friendly Guide for Farmers, Administrators, and Students*

---

## 📄 Pangasinan State University - Bayambang Campus

### SoilSync User Manual
**"AI-Powered Soil Testing Made Simple"**

*BSIT 3-1 DA Research Project*

---

## 📌 Table of Contents
1. [Welcome to SoilSync](#-welcome-to-soilsync)
2. [Meet Your SoilPOD Device](#-meet-your-soilpod-device)
3. [Setting Up the Mobile App](#-setting-up-the-mobile-app)
4. [Getting Crop Recommendations](#-getting-crop-recommendations)
5. [Using the Database Website (For Admins)](#-using-the-database-website-for-admins)
6. [AI Model Retraining (For Admins)](#-ai-model-retraining-for-admins)
7. [Troubleshooting & FAQs](#-troubleshooting--faqs)
8. [Meet the Developers](#-meet-the-developers)

---

## 🌱 Welcome to SoilSync
SoilSync is an easy-to-use smart farming system. It helps you test your soil instantly and recommends the best crops to plant.

### ⏳ The Old Way (Manual Testing)
1. **Dig up dirt**: Farmers manually collect soil samples from their fields.
2. **Send to lab**: Drive or mail samples to a faraway agricultural laboratory.
3. **Pay high fees**: Pay expensive laboratory testing fees.
4. **Wait weeks**: Wait 1 to 2 weeks for a paper report.
5. **Guess crops**: Make planting decisions by trying to interpret numbers they might not understand.

### ⚡ The SoilSync Way (Instant AI)
1. **Dip the sensor**: Insert the smart SoilPOD sensor directly into the soil.
2. **Read results**: Instantly see your soil measurements on your phone screen.
3. **Get weather**: The app automatically fetches your location's weather and rainfall.
4. **AI recommendation**: Our AI brain instantly tells you which crop will grow best.
5. **Save history**: The app securely saves all your tests so you can view them anytime.

---

## 🔌 Meet Your SoilPOD Device
The SoilPOD is the physical device that measures your soil.

### 📊 What it Measures
*   **Moisture**: How wet or dry the soil is.
*   **Temperature**: How warm or cold the soil is.
*   **pH Level**: How acidic or alkaline the soil is (very important for plant growth!).
*   **NPK Nutrients**: Nitrogen (N), Phosphorus (P), and Potassium (K) levels, which feed your crops.

### 🔌 How to Plug It In
1. Connect the **Black Probe** to the **Controller Box**.
2. Plug the **Power Adapter (9V-24V)** into the wall and connect it to the Controller Box.
3. The status light on the Controller Box will turn on.
4. The device will automatically start broadcasting a Bluetooth signal named **"SoilSync-ESP32"** so your phone can find it.

---

## 📱 Setting Up the Mobile App
Get started on your phone in a few simple steps.

### 🔑 Registration & Login
1. Open the **SoilSync** app on your phone.
2. Tap **Register** to create an account. Fill in a username, email, password, your farm name, and your farm size.
3. Log in using either your **Username** or your **Email** address!

### 📍 Setting Your Location
1. Go to the **Settings** page (tap the gear icon in the top-right corner of the dashboard).
2. Tap **Location Settings**.
3. Tap **Use GPS** to let the app automatically find your exact location, or tap one of the quick buttons (e.g. Baguio, Davao, Cebu).
4. Tap **Save Location**.

> [!TIP]
> The app uses this location to fetch real-time rainfall forecasts automatically. This is required to recommend the perfect crop!

---

## 🌾 Getting Crop Recommendations
Follow these steps to analyze your soil and get immediate crop suggestions.

### Step 1: Connect your phone to the SoilPOD
*   Turn on your phone's Bluetooth.
*   Pair with **"SoilSync-ESP32"** in your phone settings.
*   In the SoilSync app dashboard, tap the connection status button (it will turn green once connected).

### Step 2: Take a Reading
*   Push the metal prongs of the SoilPOD probe into the damp ground.
*   In the app, toggle to **Sensor Mode**. The app will instantly display the live Nitrogen, Phosphorus, Potassium, pH, and Temperature levels!
*   *Note: If you don't have the sensor, toggle to **Manual Mode** and type the values yourself.*

### Step 3: Get the Recommendation
*   Tap the big green button: **"Analyze Soil & Recommend Crop"**.
*   Within a second, the AI will display the recommended crop (like Rice, Maize, or Mango) along with a **Confidence Score** (how sure the AI is).
*   Read the friendly growing tips and alternative crop suggestions.

---

## 💻 Using the Database Website
*For Administrators and Farm Owners*

The database website lets you manage the system from any computer.

### 🔑 How to Access
1. Open your computer's browser and go to: `http://localhost:8000/`
2. Log in using your administrator username and password.

### 📈 What You Can Do
*   **Main Dashboard**: View charts showing total predictions made and the most commonly recommended crops.
*   **User Management**: View all registered farmers. You can edit their roles, or deactivate/delete users if they leave the cooperative.
*   **View History**: Review a list of all soil tests, showing NPK levels, pH, and what crop the AI recommended.
*   **Download Reports**: Click **Export to PDF** or **Export to CSV** to instantly download a report spreadsheet or printable PDF of all test records.

---

## 🤖 AI Model Retraining
*For Administrators*

Over time, you can upload new research data to make the crop recommendations even more accurate.

### Step 1: Upload a Data Spreadsheet (CSV)
1. In the App Settings, tap **Model Retraining**.
2. Tap **Import CSV** and select a file with new soil records.
3. Choose **Merge** to add to existing data, or **Replace** to start fresh.

### Step 2: Train the AI Brain
1. Tap the **Retrain Model** button and wait for the loading bar to finish.
2. You will see a results panel showing the new accuracy score (e.g., `96.8%`).
3. View the **Feature Importance** chart showing which parameters (like Nitrogen or pH) matter most.

### Step 3: Deploy the New Model
1. If you are satisfied with the accuracy, tap **Deploy**.
2. The system instantly switches to this version for all future tests!

---

## ❓ Troubleshooting & FAQs

### 🔌 Bluetooth Connection Issues
*   Make sure the SoilPOD is plugged in and the lights are on.
*   Check if another phone is already connected to it. Disconnect it first.
*   Turn your phone's Bluetooth off and on, then try again.

### 📊 Sensor Reading Issues
*   Ensure the metal probe is pushed firmly into damp soil. The sensor does not read well in completely dry soil.
*   Check that all wire connections on the controller box are tight.

### 🌐 Network & Server Issues
*   Make sure your phone and the computer hosting the database website are connected to the exact same Wi-Fi network.
*   Check that the IP address in your App settings is typed correctly.

### 📍 Location & Rainfall Issues
*   Ensure location permissions are allowed for the SoilSync app.
*   Turn on your phone's GPS/Location settings.

---

## 👥 Meet the Developers
This research and application was proudly developed by the BSIT 3-1 DA development team:

*   **Roger Macaraeg** — *Project Lead & Systems Architect*
    *   Coordinated the project flow, hardware-software connections, and integrated Bluetooth data streams.
*   **Carl Ivan Alatan** — *Backend Developer & ML Engineer*
    *   Designed the Django database server, built the Random Forest AI model, and created the web dashboard.
*   **Dhea Charissed Barte** — *Mobile App Developer & UI Designer*
    *   Crafted the Flutter mobile interface, developed the dashboard widgets, and added settings pages.
*   **Charles Emmanuel Benitez** — *Hardware Specialist & Documenter*
    *   Wired and calibrated the SoilPOD sensor, uploaded firmware, and compiled dataset records.
