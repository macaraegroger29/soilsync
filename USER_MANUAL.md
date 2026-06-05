# SoilSync: User Manual & Guided Tour
*A Step-by-Step Booklet for Farmers, Administrators, and Students*

---

================================================================================
|                                                                              |
|                              [ PAGE 1 - COVER ]                              |
|                                                                              |
|                           PANGASINAN STATE UNIVERSITY                        |
|                                Bayambang Campus                              |
|                                                                              |
|                                                                              |
|                                  SOILSYNC                                    |
|                                                                              |
|                                USER MANUAL                                   |
|                                                                              |
|                                                                              |
|                   "AI-Powered Soil Testing Made Simple"                      |
|                                                                              |
|                                                                              |
|                                                                              |
|                         BSIT 3-1 DA Research Project                         |
|                                                                              |
================================================================================

---

================================================================================
|                                                                              |
|                        [ PAGE 2 - TABLE OF CONTENTS ]                        |
|                                                                              |
|     1. Welcome to SoilSync (What is it?) .......................... Page 3    |
|     2. Meet your SoilPOD Device ................................... Page 4    |
|     3. Setting up the Mobile App .................................. Page 5    |
|     4. Getting Crop Recommendations ............................... Page 6    |
|     5. Using the Database Website (For Admins) .................... Page 7    |
|     6. AI Retraining (For Admins) ................................. Page 8    |
|     7. Troubleshooting (Common Fixes) ............................. Page 9    |
|     8. Meet the Developers ........................................ Page 10   |
|                                                                              |
================================================================================

---

================================================================================
|                                                                              |
|                         [ PAGE 3 - WELCOME TO SOILSYNC ]                      |
|                                                                              |
|   🌱 What is SoilSync?                                                       |
|   SoilSync is an easy-to-use smart farming system. It helps you test your    |
|   soil instantly and recommends the best crops to plant.                     |
|                                                                              |
|   ⏳ The Old Way (Manual Testing):                                           |
|   1. Farmers manually dig up dirt.                                           |
|   2. Send it to a faraway laboratory.                                        |
|   3. Pay expensive laboratory fees.                                          |
|   4. Wait 1 to 2 weeks for a paper report.                                   |
|   5. Guess which crop to plant based on numbers you don't understand.        |
|                                                                              |
|   ⚡ The SoilSync Way (Instant AI):                                          |
|   1. Dip the smart SoilPOD sensor in the soil.                               |
|   2. Instantly see measurements on your phone.                               |
|   3. The app automatically fetches your weather and rainfall details.        |
|   4. Our AI brain instantly tells you which crop will grow best.             |
|   5. Saves your test history so you never lose your data.                    |
|                                                                              |
================================================================================

---

================================================================================
|                                                                              |
|                        [ PAGE 4 - MEET THE SOILPOD ]                         |
|                                                                              |
|   🔌 What is the SoilPOD?                                                    |
|   The SoilPOD is the small physical device that does the soil measuring. It  |
|   consists of:                                                               |
|   1. The Black Probe (inserts into the ground).                              |
|   2. The Controller Box (the brain with flashing lights).                    |
|                                                                              |
|   📊 What does it measure?                                                   |
|   - Moisture: How wet or dry the soil is.                                    |
|   - Temperature: How warm or cold the soil is.                               |
|   - pH level: How acidic or alkaline the soil is (crucial for plants!).      |
|   - NPK Nutrients: Nitrogen (N), Phosphorus (P), and Potassium (K) levels    |
|     which feed your crops.                                                   |
|                                                                              |
|   🔌 How to Plug It In:                                                      |
|   - Connect the Black Probe to the Controller Box.                           |
|   - Plug the power adapter (9V-24V) into the wall and connect it to the      |
|     Controller Box.                                                          |
|   - The status light on the Controller Box will turn on.                     |
|   - It will automatically start broadcasting a Bluetooth signal called       |
|     "SoilSync-ESP32" so your phone can find it.                              |
|                                                                              |
================================================================================

---

================================================================================
|                                                                              |
|                      [ PAGE 5 - SETTING UP THE MOBILE APP ]                  |
|                                                                              |
|   📱 Getting Started:                                                        |
|   1. Open the SoilSync app on your phone.                                    |
|   2. Click "Register" to create an account. Type in a username, email,       |
|      password, your farm name, and your farm size.                           |
|   3. Login using either your Username or your Email address!                 |
|                                                                              |
|   📍 Setting Your Location (Very Important for Rainfall):                    |
|   1. Go to the Settings page (gear icon in the top right).                   |
|   2. Tap "Location Settings".                                                |
|   3. Tap "Use GPS" to let the app automatically find your exact location,     |
|      or tap one of the quick buttons (e.g. Baguio, Davao, Cebu).             |
|   4. Tap "Save Location".                                                    |
|   *Why? The app uses this location to fetch real-time rainfall forecasts     |
|   automatically, which is required to recommend the perfect crop!*           |
|                                                                              |
================================================================================

---

================================================================================
|                                                                              |
|                    [ PAGE 6 - GETTING CROP RECOMMENDATIONS ]                  |
|                                                                              |
|   🌱 How to Test Your Soil:                                                  |
|                                                                              |
|   Step 1: Connect your phone to the SoilPOD                                  |
|   - Turn on your phone's Bluetooth. Pair with "SoilSync-ESP32".              |
|   - In the app dashboard, tap the connection button. It will turn green.     |
|                                                                              |
|   Step 2: Take a Reading                                                     |
|   - Push the metal prongs of the SoilPOD probe into the damp ground.         |
|   - In the App, toggle to "Sensor Mode". The app will instantly display the  |
|     live Nitrogen, Phosphorus, Potassium, pH, and Temperature levels!        |
|   *Note: If you don't have the sensor, toggle to "Manual Mode" and type      |
|   the values yourself.*                                                      |
|                                                                              |
|   Step 3: Get the Recommendation                                             |
|   - Tap the big green button: "Analyze Soil & Recommend Crop".               |
|   - Within a second, the AI will display the recommended crop (like Rice,    |
|     Maize, or Mango) along with a Confidence Score (how sure the AI is).     |
|   - Read the friendly growing tips and alternative crop suggestions.         |
|                                                                              |
================================================================================

---

================================================================================
|                                                                              |
|                     [ PAGE 7 - USING THE DATABASE WEBSITE ]                  |
|                                                                              |
|   💻 What is the Database Website?                                           |
|   It is a website (for administrators or farm owners) that lets you manage   |
|   the system from any computer.                                              |
|                                                                              |
|   🔑 How to Access:                                                          |
|   1. Go to `http://localhost:8000/` in your computer's browser.              |
|   2. Log in using your administrator username and password.                  |
|                                                                              |
|   📈 What You Can Do:                                                        |
|   - Main Dashboard: View charts showing total predictions made and the       |
|     most commonly recommended crops.                                         |
|   - User Management: View all registered farmers. You can edit their roles,  |
|     or deactivate/delete users if they leave the cooperative.                |
|   - View History: Review a list of all soil tests, showing NPK levels, pH,   |
|     and what crop the AI recommended.                                        |
|   - Download Reports: Click "Export to PDF" or "Export to CSV" to instantly  |
|     download a report spreadsheet or printable PDF of all test records.      |
|                                                                              |
================================================================================

---

================================================================================
|                                                                              |
|                         [ PAGE 8 - AI RETRAINING ]                           |
|                                                                              |
|   🤖 How to Make the AI Smarter:                                             |
|   Over time, you can upload new research data to make the crop               |
|   recommendations even more accurate. This dashboard is for Admins only.     |
|                                                                              |
|   Step 1: Upload a Data Spreadsheet (CSV)                                    |
|   - In the App Settings, tap "Model Retraining".                             |
|   - Tap "Import CSV" and select a file with new soil records.                |
|   - Choose "Merge" to add to existing data, or "Replace" to start fresh.     |
|                                                                              |
|   Step 2: Train the AI Brain                                                 |
|   - Tap the "Retrain Model" button.                                          |
|   - Wait for the loading bar to finish.                                      |
|   - You will see a results panel showing the new accuracy score (e.g. 96%).  |
|   - It also shows a "Feature Importance" chart, displaying which parameter   |
|     (like Nitrogen or pH) matters most in making the crop decisions.         |
|                                                                              |
|   Step 3: Deploy the New Model                                               |
|   - If you are satisfied with the accuracy, tap the "Deploy" button.         |
|   - The system instantly switches to this version for all future tests!      |
|                                                                              |
================================================================================

---

================================================================================
|                                                                              |
|                         [ PAGE 9 - TROUBLESHOOTING ]                         |
|                                                                              |
|   ❓ Device Bluetooth is not connecting?                                     |
|   - Make sure the SoilPOD is plugged in and the lights are on.               |
|   - Check if another phone is already connected to it. Disconnect it first.  |
|   - Turn your phone's Bluetooth off and on, then try again.                  |
|                                                                              |
|   ❓ Sensor displays "Invalid response"?                                     |
|   - Ensure the metal probe is pushed firmly into damp soil. The sensor       |
|     does not read well in completely dry soil.                               |
|   - Check that all wire connections on the controller box are tight.         |
|                                                                              |
|   ❓ App says "Network Error" when analyzing?                                |
|   - Make sure your phone and the computer hosting the database website are   |
|     connected to the exact same Wi-Fi network.                               |
|   - Check that the IP address in your App settings is typed correctly.       |
|                                                                              |
|   ❓ Location coordinates or rainfall values are zero?                       |
|   - Ensure location permissions are allowed for the SoilSync app.            |
|   - Turn on your phone's GPS/Location settings.                              |
|                                                                              |
================================================================================

---

================================================================================
|                                                                              |
|                        [ PAGE 10 - MEET THE DEVELOPERS ]                     |
|                                                                              |
|   This research and application was proudly developed by the BSIT 3-1 DA     |
|   development team:                                                          |
|                                                                              |
|   👨‍💻 Roger Macaraeg                                                           |
|      *Project Lead & Systems Architect*                                      |
|      Coordinated the project flow, hardware-software connections, and        |
|      integrated Bluetooth data streams.                                      |
|                                                                              |
|   👨‍💻 Carl Ivan Alatan                                                         |
|      *Backend Developer & ML Engineer*                                       |
|      Designed the Django database server, built the Random Forest AI model,  |
|      and created the web dashboard.                                          |
|                                                                              |
|   👩‍💻 Dhea Charissed Barte                                                    |
|      *Mobile App Developer & UI Designer*                                    |
|      Crafted the Flutter mobile interface, developed the dashboard widgets,  |
|      and added settings pages.                                               |
|                                                                              |
|   👨‍💻 Charles Emmanuel Benitez                                                 |
|      *Hardware Specialist & Documenter*                                      |
|      Wired and calibrated the SoilPOD sensor, uploaded firmware, and         |
|      compiled dataset records.                                               |
|                                                                              |
================================================================================
