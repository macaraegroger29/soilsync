#include <WiFi.h>
#include <WebServer.h>

#define RXD2 16  // RO
#define TXD2 17  // DI
#define RE 2
#define DE 4

HardwareSerial modbusSerial(2);

// WiFi credentials
const char* ssid = "return 0;";
const char* password = "helloworld";

WebServer server(80);

// Global variables to store sensor readings
float moisture_percent = 0;
float temperature = 0;
float ph = 0;
uint16_t nitrogen = 0, phosphorus = 0, potassium = 0;

void setup() {
  Serial.begin(115200);
  modbusSerial.begin(4800, SERIAL_8N1, RXD2, TXD2);

  pinMode(RE, OUTPUT);
  pinMode(DE, OUTPUT);

  digitalWrite(RE, LOW);
  digitalWrite(DE, LOW);

  Serial.println("Starting RS485 sensor test...");

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected. IP address: ");
  Serial.println(WiFi.localIP());

  // HTTP endpoint for sensor data
  server.on("/sensor", HTTP_GET, []() {
    String json = "{";
    json += "\"moisture\":" + String(moisture_percent, 1) + ",";
    json += "\"temperature\":" + String(temperature, 1) + ",";
    json += "\"ph\":" + String(ph, 1) + ",";
    json += "\"nitrogen\":" + String(nitrogen) + ",";
    json += "\"phosphorus\":" + String(phosphorus) + ",";
    json += "\"potassium\":" + String(potassium);
    json += "}";
    server.send(200, "application/json", json);
  });

  server.begin();
}

void loop() {
  server.handleClient();

  byte request[] = {0x01, 0x03, 0x00, 0x00, 0x00, 0x07, 0x04, 0x08};

  digitalWrite(DE, HIGH);
  digitalWrite(RE, HIGH);
  delay(2);
  modbusSerial.write(request, sizeof(request));
  modbusSerial.flush();
  delay(2);
  digitalWrite(DE, LOW);
  digitalWrite(RE, LOW);

  delay(300); // Wait for response

  byte response[25]; // Max response size
  int i = 0;
  while (modbusSerial.available() && i < sizeof(response)) {
    response[i++] = modbusSerial.read();
  }

  if (i >= 17) { // Valid frame should be at least 17 bytes for 7 registers
    uint16_t moisture    = (response[3] << 8) | response[4];
    uint16_t temp_raw    = (response[5] << 8) | response[6];
    uint16_t ec          = (response[7] << 8) | response[8];
    uint16_t ph_raw      = (response[9] << 8) | response[10];
    uint16_t nitrogen    = (response[11] << 8) | response[12];
    uint16_t phosphorus  = (response[13] << 8) | response[14];
    uint16_t potassium   = (response[15] << 8) | response[16];

    float temperature = temp_raw / 10.0;
    float ph = ph_raw / 10.0;
    float moisture_percent = moisture / 10.0;

    Serial.println("===== Soil Sensor Readings =====");
    Serial.print("Moisture: "); Serial.print(moisture_percent); Serial.println(" %");
    Serial.print("Temperature: "); Serial.print(temperature); Serial.println(" °C");
    Serial.print("Conductivity: "); Serial.print(ec); Serial.println(" uS/cm");
    Serial.print("pH: "); Serial.print(ph); Serial.println("");
    Serial.print("Nitrogen: "); Serial.print(nitrogen); Serial.println(" mg/kg");
    Serial.print("Phosphorus: "); Serial.print(phosphorus); Serial.println(" mg/kg");
    Serial.print("Potassium: "); Serial.print(potassium); Serial.println(" mg/kg");
    Serial.println("=================================");
  } else {
    Serial.println("Invalid or incomplete response.");
  }

  delay(5000);
}
