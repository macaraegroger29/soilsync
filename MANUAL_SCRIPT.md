# SoilSync: AI-Powered Soil Analysis & Crop Recommendation System
## Complete Operational Manual & System Script
**For Developers, Administrators, Farmers, and QA Testers**

---

## 1. System Overview & Architecture

**SoilSync** is an end-to-end agricultural technology platform designed to automate soil testing and deliver real-time, AI-driven crop recommendations. The system consists of three core components:
1. **SoilPOD (IoT Device)**: An ESP32-based hardware pod connected to a 7-in-1 Modbus RS485 soil sensor. It measures soil moisture, temperature, pH, nitrogen (N), phosphorus (P), potassium (K), and electrical conductivity (EC), and streams this data via Bluetooth Serial (SPP).
2. **SoilSync Mobile Application (Flutter)**: A cross-platform mobile app that pairs with the SoilPOD over Bluetooth. It fetches environmental parameters, gets precise location coordinates to obtain local rainfall forecasts from Open-Meteo, sends the aggregated data to the backend API, displays crop recommendations, and tracks historical tests. It also supports manual data input and a 2×2 grid sampling interface.
3. **SoilSync Backend & Database Website (Django & SQLite)**: A Django REST framework application that exposes REST endpoints for user authentication, weather fetching, and prediction. It runs a Random Forest classifier model to predict recommendations and stores all accounts and test histories in a SQLite database. It also provides a web-based administrative dashboard for CRUD operations on users, sensors, and predictions, as well as an admin retraining interface.

```
┌─────────────────────────────────────────────────────────────┐
│                       SOILSYNC FLOW                         │
└─────────────────────────────────────────────────────────────┘
  ┌──────────────┐                 ┌───────────────┐
  │   SoilPOD    │  Bluetooth SPP  │  Mobile App   │
  │ (ESP32 + RS485) ──────────────> │   (Flutter)   │
  └──────────────┘                 └───────┬───────┘
                                           │
                                           │ HTTP REST APIs
                                           │ (JSON over WiFi/Cellular)
                                           v
  ┌────────────────────────────────────────────────────────┐
  │                 Django Backend Server                  │
  │  ┌─────────────────┐  ┌───────────────┐  ┌──────────┐  │
  │  │  Database Web   │  │ Random Forest │  │ SQLite   │  │
  │  │  Dashboard Panel│  │   ML Engine   │  │ Database │  │
  │  └─────────────────┘  └───────────────┘  └──────────┘  │
  └────────────────────────────────────────────────────────┘
```

---

## 2. Hardware Setup Guide (SoilPOD IoT Device)

The **SoilPOD** consists of an ESP32 microcontroller, a MAX485 TTL-to-RS485 transceiver module, and a 7-in-1 NPK/pH/Temp/Moisture/EC Soil Sensor.

### 2.1. Wiring Diagram & Pin Map

Connect the components according to the following scheme:

| From Component | Pin | To Component | Pin | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **MAX485 Module** | **VCC** | ESP32 Board | **5V / VIN** | Power supply for transceiver |
| **MAX485 Module** | **GND** | ESP32 Board | **GND** | Common ground reference |
| **MAX485 Module** | **RO (Receiver Out)**| ESP32 Board | **GPIO 16 (RXD2)**| Hardware Serial 2 RX |
| **MAX485 Module** | **DI (Driver In)** | ESP32 Board | **GPIO 17 (TXD2)**| Hardware Serial 2 TX |
| **MAX485 Module** | **RE (Receiver Enable)**| ESP32 Board | **GPIO 2** | Controlled pin (active low) |
| **MAX485 Module** | **DE (Driver Enable)** | ESP32 Board | **GPIO 4** | Controlled pin (active high) |
| **MAX485 Module** | **A (Non-inverting)**| 7-in-1 Sensor | **Yellow Wire (A)**| RS485 Differential Line A |
| **MAX485 Module** | **B (Inverting)** | 7-in-1 Sensor | **Blue Wire (B)** | RS485 Differential Line B |
| **7-in-1 Sensor** | **VCC (Power)** | Power Supply | **9V - 24V DC (+)**| External power required |
| **7-in-1 Sensor** | **GND (Ground)** | Power Supply / ESP32| **GND (-)** | Connect all grounds together |

> [!IMPORTANT]
> - Do **not** power the 7-in-1 Modbus Soil Sensor directly from the ESP32's 3.3V or 5V pins. The sensor requires a stable DC voltage between 9V and 24V.
> - Ensure you tie the ground of the external DC power supply to the ground (GND) of the ESP32 to maintain a common ground reference.
> - Jumper or connect the **RE** and **DE** pins on the MAX485 module together, so they can be driven simultaneously by the ESP32 (High for transmission, Low for reception).

### 2.2. Firmware Installation
1. Open the **Arduino IDE**.
2. Go to **File > Preferences** and add the ESP32 board URL to the "Additional Boards Manager URLs": `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. Go to **Tools > Board > Boards Manager...**, search for **esp32** by Espressif Systems, and click **Install**.
4. Open the firmware file: [soil_sensor_new.ino](file:///c:/Users/jao/projects/soilsync/soil_sensor_new.ino).
5. Select the appropriate ESP32 Board (e.g., `ESP32 Dev Module`) under **Tools > Board** and select your active serial port under **Tools > Port**.
6. Click **Upload** (arrow icon). If the console says "Connecting...", press and hold the **BOOT** button on your ESP32 board until the upload progress percentage starts moving.
7. Open the **Serial Monitor** (set baud rate to `115200`) and verify that the output prints: `Starting RS485 sensor test...` and `Bluetooth device started, now you can pair it!`.

---

## 3. Database Website & Backend Setup Guide

The backend is built with Django, utilizing Django REST Framework (DRF) for APIs, and templates for the administrative database website.

### 3.1. Installation & Environment Configuration
1. Open a **PowerShell** window in the backend directory: `c:\Users\jao\projects\soilsync\soilsync_backend`.
2. Check if a virtual environment is active. If not, activate the pre-configured one:
   ```powershell
   .venv\Scripts\activate
   ```
3. Install dependencies from the requirements file:
   ```powershell
   pip install -r requirements.txt
   ```
4. Perform database migrations to initialize tables (SQLite):
   ```powershell
   python manage.py migrate
   ```
5. Create an administrative superuser account (this account has the `admin` role by default in the custom user table):
   ```powershell
   python manage.py createsuperuser
   ```
   *Follow the prompts to enter a username (e.g., `admin`), email, and password.*

### 3.2. Launching the Server
Start the development server. Exposing it on `0.0.0.0` allows devices on the same local network (such as your test mobile phone) to connect:
```powershell
python manage.py runserver 0.0.0.0:8000
```
Verify the server is running by opening a web browser and navigating to:
- **Database Website Home/Dashboard**: `http://localhost:8000/` (redirects to login)
- **Django Standard Admin Panel**: `http://localhost:8000/admin/`
- **Root REST API View**: `http://localhost:8000/api/`

---

## 4. Mobile Application Setup Guide

The mobile client is built using Flutter and connects to the Django REST API.

### 4.1. Configuration
1. Open the file [lib/config.dart](file:///c:/Users/jao/projects/soilsync/lib/config.dart).
2. Set the `baseUrl` to point to the IP address of your running backend server:
   - For testing on the **Android Emulator**, use: `http://10.0.2.2:8000`
   - For testing on a **Physical Android/iOS Device**, determine your computer's local IP address (e.g., using `ipconfig` on Windows) and set it to: `http://192.168.x.x:8000`
   - Ensure the testing device is connected to the same Wi-Fi network as the backend server.

### 4.2. Running the Application
1. Connect your physical device or start your emulator.
2. In the project root directory (`c:\Users\jao\projects\soilsync`), fetch dependencies:
   ```powershell
   flutter pub get
   ```
3. Run the application:
   ```powershell
   flutter run
   ```

---

## 5. End-to-End Manual Operational Script (Test Scenarios)

Follow these scenarios step-by-step to operate and test the complete SoilSync system.

### Scenario 1: User Onboarding (Registration & Login)
*Verify that users can register, choose a role, input farm details, and log in securely using either username or email.*

| Step | Action | Input / Data | Expected Output |
| :--- | :--- | :--- | :--- |
| **1.1** | Open the SoilSync Mobile App or navigate to `http://localhost:8000/register/` on the website. Click **Register** / **Sign Up**. | Choose: **Register Screen** | The signup form is displayed with fields for username, email, phone, location, password, farm name, and farm size. |
| **1.2** | Fill out the registration form. Select the role **Farmer** or **Home Grower**. | **Username**: `greenfinger`<br>**Email**: `farmer@soilsync.com`<br>**Password**: `securepass123`<br>**Role**: Farmer<br>**Farm Name**: Sunshine Valley<br>**Farm Size**: 2.5 Hectares | **Mobile App**: "Registration Successful" toast message appears; user is redirected to the Login Screen.<br>**Website**: Redirected to `http://localhost:8000/login/` with a success message banner. |
| **1.3** | Attempt login with the registered **username**. | **Username**: `greenfinger`<br>**Password**: `securepass123` | Login succeeds. Redirected to the User Dashboard page. User token is stored in local storage/session. |
| **1.4** | Log out of the session, then test login with the registered **email**. | **Email**: `farmer@soilsync.com`<br>**Password**: `securepass123` | Login succeeds. Redirected to the User Dashboard page. This verifies the username-or-email authentication backend. |
| **1.5** | Test invalid login parameters. | **Username**: `greenfinger`<br>**Password**: `wrongpassword` | Access denied. Alert message: *"No user found with this username or email."* or *"Invalid credentials!"*. |

---

### Scenario 2: Device and Location Settings Configuration
*Configure geographic coordinates to fetch real-time weather and rainfall forecasts, and set up WiFi credentials.*

| Step | Action | Input / Data | Expected Output |
| :--- | :--- | :--- | :--- |
| **2.1** | On the Mobile App, tap the **Settings** icon on the top right of the dashboard. | Navigate to: **Settings Page** | Displays structured options: *App Settings* (Theme/Notifications), *Device & Location Settings*, *Data & AI Management*, and *App Information*. |
| **2.2** | Tap on **Location Settings**. | Open: **Location Settings Widget** | Displays latitude/longitude inputs, a list of Philippine city preset buttons, and a GPS capture button. |
| **2.3** | Tap the **Baguio** preset button or enter coordinates manually, then click **Save Location**. | **Latitude**: `16.4023`<br>**Longitude**: `120.5960` | Coordinates are stored in local app preferences. A confirmation popup appears. |
| **2.4** | Alternatively, tap the **Use GPS** button. | Click: **GPS Capture** | App requests location permission. If granted, fields automatically populate with current device GPS coordinates. |
| **2.5** | Tap **WiFi Settings** card inside Device Settings. | Enter WiFi parameters:<br>**SSID**: *Your_Router_SSID*<br>**Password**: *Router_Password* | ESP32 connection credentials are Saved/Transmitted via Bluetooth (used by the SoilPOD for standalone IoT operations). |

---

### Scenario 3: Connecting the App to the SoilPOD IoT Device
*Establish a secure Classic Bluetooth Serial (SPP) connection to stream soil readings.*

| Step | Action | Input / Data | Expected Output |
| :--- | :--- | :--- | :--- |
| **3.1** | Power on the **SoilPOD** hardware unit by plugging in the external power adapter. | Power source: **9V-24V DC** | The ESP32's status LEDs light up. Classic Bluetooth advertising starts. |
| **3.2** | Open your phone's system Bluetooth settings and search for discoverable devices. | Scan: Bluetooth | You should find a device named **`SoilSync-ESP32`**. Select it to pair. (Default passcode is usually not required or `0000`/`1234`). |
| **3.3** | Open the SoilSync App, go to the User Dashboard, and tap the **Sensor Connection** status bar. | Select device: **`SoilSync-ESP32`** | The connection indicator turns green, showing **"Connected to SoilPOD"**. |
| **3.4** | Check the terminal / Serial Monitor of the ESP32. | Observe logs: Serial Monitor | Logs show `Bluetooth client connected`. The SoilPOD starts streaming CSV sensor packets every 5 seconds. |
| **3.5** | Turn off phone Bluetooth to simulate disconnection. | Turn Off Bluetooth | The SoilPOD detects client loss. ESP32 logs show a restart of Bluetooth advertising every 15 seconds to remain discoverable. |

---

### Scenario 4: Soil Data Analysis & Prediction Flow
*Perform soil analysis using manual inputs or automated SoilPOD readings to receive AI crop recommendations.*

| Step | Action | Input / Data | Expected Output |
| :--- | :--- | :--- | :--- |
| **4.1** | **Option A (Manual Input)**: On the User Dashboard, set the toggle to **Manual Mode**. Enter soil metrics manually. | **N**: `80`, **P**: `40`, **K**: `40`<br>**pH**: `6.5`, **Temp**: `26 °C`, **Humidity**: `75%`<br>**Rainfall**: `200 mm` | Form validation passes (no empty fields, numbers in valid ranges). |
| **4.2** | **Option B (Sensor Mode)**: Turn on **Sensor Auto-Collection Mode**. Ensure SoilPOD is connected. | Dip SoilPOD sensor probe in a damp soil container. | N, P, K, pH, Temperature, and Humidity fields in the App automatically update in real-time every 5 seconds with live values from the SoilPOD. |
| **4.3** | In Sensor Mode, observe the **Rainfall** field. | Location set to Baguio (16.4023, 120.5960). | The Rainfall field is auto-filled by the Weather Service, fetching real-time precipitation forecast data from Open-Meteo API instead of using placeholders. |
| **4.4** | Click the **Analyze Soil & Recommend Crop** button. | Click: **Submit** | A loading spinner appears while sending a POST request to `/api/predict/`. |
| **4.5** | Review the **Recommendation Card** that pops up. | View prediction output. | Displays the predicted primary crop (e.g., **`rice`** or **`maize`**) with a Confidence Score (e.g., **`94.5%`**), detailed growing notes, pH suitability indicator, and lists the top alternative crop recommendations. |

---

### Scenario 5: 2×2 Grid Sampling Field Analysis
*Perform systematic grid testing to analyze soil variation across a farming field.*

| Step | Action | Input / Data | Expected Output |
| :--- | :--- | :--- | :--- |
| **5.1** | On the User Dashboard, tap the **Grid Sampling** tab or button. | Open: **Grid Sampling Mode** | Displays a 2×2 grid layout representing 4 sampling sectors: **North-West (NW)**, **North-East (NE)**, **South-West (SW)**, and **South-East (SE)**. |
| **5.2** | Tap on **Sector 1 (NW)**. Connect SoilPOD, insert probe, and tap **Record Reading**. | Sector: NW | Sector NW changes status from *Pending* to *Recorded*, displaying active NPK, pH, and Temperature values. |
| **5.3** | Move to the next field sector and repeat for NE, SW, and SE sectors. | Sectors: NE, SW, SE | All 4 cells are marked as recorded. A summary of average parameters is displayed below. |
| **5.4** | Tap **Generate Field Analysis Report**. | Click: **Generate** | The App communicates with `/api/predict/` for each cell, mapping out recommendation variance. |
| **5.5** | Inspect the **Field Grid Analysis Report** summary. | View grid report card. | Displays a heat-map representation of the field, advising if different zones need different fertilizers or highlighting the crop most suitable for the entire field average. |

---

### Scenario 6: Database Website Panel (Admin Operations)
*Manage application records, review prediction histories, and generate reports using the Django web dashboard.*

| Step | Action | Input / Data | Expected Output |
| :--- | :--- | :--- | :--- |
| **6.1** | Open a browser and navigate to `http://localhost:8000/login/`. Log in with your admin credentials. | **Username**: `admin`<br>**Password**: `adminpass123` | Access granted. Redirected to the web-based **Database Dashboard** (`/`). |
| **6.2** | Examine the **Dashboard Stats Cards & Graphs**. | View Dashboard Home | Displays metrics cards: *Total Users*, *Sensor Devices*, *API Predictions*, *Average pH*, and a dynamic chart displaying the distribution of recommended crops. |
| **6.3** | In the left sidebar, click **Users** to open the user table. | Navigate: **Users Table** | List of all registered users is displayed. Admin can edit user roles, activate/deactivate accounts, or delete users. |
| **6.4** | Click **Edit** on a user, modify fields, and click **Save**. | Set: `is_active` to `False` | User status is updated. If the user tries to login from the Mobile App now, they will be blocked with an *"Account deactivated"* message. |
| **6.5** | In the sidebar, click **Crop Recommendations** / **API Soil Data**. | Navigate: **Recommendations Table** | Displays a complete list of soil metrics (N, P, K, pH, etc.) submitted by users and the corresponding predictions. |
| **6.6** | Click **Export to CSV** or **Export to PDF** buttons. | Click: **Export** | Browser downloads a formatted report (`api_soil_data_report.csv` or `api_soil_data_report.pdf`) containing the history table, average metrics, and timestamp logs. |

---

### Scenario 7: Advanced Data & AI Management (Retraining Dashboard)
*Upload new training data, trigger ML model training, compare accuracies, and deploy the new model version.*

| Step | Action | Input / Data | Expected Output |
| :--- | :--- | :--- | :--- |
| **7.1** | In the Mobile App (logged in as `admin`), navigate to **Settings > Model Retraining**. | Open: **Model Retraining Dashboard** | Displays model versioning list, current active version status, and the Upload CSV option. |
| **7.2** | Tap **Import CSV** and select a valid soil training data file. Choose **Merge** mode. | [Upload CSV File](file:///c:/Users/jao/projects/soilsync/soilsync_backend/requirements.txt)<br>*(Use a file containing columns: `N,P,K,temperature,humidity,ph,rainfall,label`)* | File validator checks columns. Shows success toast: *"CSV uploaded successfully. X records merged."* |
| **7.3** | Tap the **Retrain Model** button. | Click: **Retrain Model** | A progress indicator appears. The backend triggers the Random Forest retraining pipeline using the updated dataset. |
| **7.4** | Once training completes, inspect the **Results Panel**. | Observe training metrics. | Visual graphs render: **Accuracy / F1 metrics** (e.g. `96.8%`), **Confusion Matrix** showing classification errors, and **Feature Importance** bar chart (e.g. Nitrogen 25%, pH 18%). |
| **7.5** | In the Model History list, find the newly generated version (e.g. `v20260605_2240`). Tap **Deploy**. | Click: **Deploy** | The new version is marked as **Active (Green)**. All future prediction requests to `/api/predict/` are routed to this model. |
| **7.6** | Re-run a prediction test (Scenario 4) to verify. | Submit: Soil Analysis | Predictions succeed, utilizing the new model version. |

---

## 6. Troubleshooting Guide

### 6.1. SoilPOD IoT Device Issues

#### A. ESP32 serial logs print: `Invalid or incomplete response.`
*   **Cause**: Incorrect wiring between ESP32, MAX485, and the soil sensor, or weak power supply.
*   **Fix**:
    1. Verify that **A** is wired to **Yellow** and **B** is wired to **Blue** on the sensor.
    2. Ensure the RE and DE pins on the MAX485 are connected together and connected to ESP32 GPIO 2 & 4.
    3. Ensure the external power supply is providing at least 9V-24V DC to the sensor and that its ground is connected to the ESP32 GND.
    4. Check if the RX/TX pins are swapped. RXD2 should go to MAX485 RO, TXD2 to DI.

#### B. The SoilPOD Bluetooth is not discoverable in system settings.
*   **Cause**: The ESP32 is already connected to another device, or the Bluetooth controller crashed.
*   **Fix**:
    1. Disconnect any other paired phones from the SoilPOD.
    2. Power-cycle the ESP32 (unplug and replug USB and power supply).
    3. Note that the firmware restarts Bluetooth advertising every 15 seconds if there is no active connection. Check the Serial Monitor to confirm advertisement triggers.

---

### 6.2. Mobile App Connectivity Issues

#### A. The app displays `Connection timeout` or `Network error` when analyzing.
*   **Cause**: The mobile phone cannot connect to the Django server.
*   **Fix**:
    1. Verify your backend server is running (`python manage.py runserver 0.0.0.0:8000`).
    2. Ensure both your computer (running the backend) and the mobile phone are connected to the same Wi-Fi network.
    3. Verify you have set the correct IP address in `lib/config.dart`.
    4. Check your computer's local firewall. You may need to create an inbound rule for TCP port `8000` to allow external connections.

#### B. GPS Location coordinates do not update.
*   **Cause**: Location permissions are denied or GPS is disabled.
*   **Fix**:
    1. Go to your phone settings, find the **SoilSync** app, and ensure location permissions are set to "Allow only while using the app".
    2. Turn on high-accuracy GPS/location services in the system status bar.
    3. If testing in an emulator, use the emulator control panel to simulate coordinates.

---

### 6.3. Django Database & Website Errors

#### A. CSV upload fails with validation error.
*   **Cause**: The CSV columns do not match the expected format exactly.
*   **Fix**:
    1. Open your CSV file in a text editor.
    2. Ensure the first line (header) matches this case-sensitive string exactly: `N,P,K,temperature,humidity,ph,rainfall,label`
    3. Ensure there are no empty rows or non-numeric values (except for the `label` column).

#### B. Operational login rejects correct username/password on the website.
*   **Cause**: Spaces or capitalization mismatch, or database out of sync.
*   **Fix**:
    1. The website uses case-insensitive username lookups, but passwords are strictly case-sensitive. Ensure no leading or trailing spaces are entered.
    2. If needed, reset the user password via Django Admin (`/admin/`) or using python terminal command:
       ```bash
       python manage.py changepassword <username>
       ```
