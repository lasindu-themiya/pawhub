#include <Wire.h>
#include <Adafruit_MLX90614.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <TinyGPS++.h>
#include <time.h>
#include <ArduinoJson.h>

const char* ssid = "lasindupc";
const char* password = "lasindu96";

const char* FIRESTORE_HOST = "https://firestore.googleapis.com/v1/projects/pawhub-678c4/databases/(default)/documents";
const char* LOCATION_PATH = "/location/dog_location";
const char* TEMPERATURE_PATH = "/temperature/dogtemp";
const char* GEOFENCE_PATH = "/geofence/dogFence";
const char* HISTORY_PATH = "/history";  

Adafruit_MLX90614 mlx = Adafruit_MLX90614();

#define GPS_RX_PIN 2
#define GPS_TX_PIN 1
#define SDA_PIN 9  
#define SCL_PIN 10 
TinyGPSPlus gps;
HardwareSerial GPSSerial(1);

// For geofence state tracking
bool was_inside_geofence = true; 

// Last known values to minimize writes
double last_lat = 0.0;
double last_lng = 0.0;
float last_object_temp = 0.0;

// Geofence data
double fence_lat = 0.0;
double fence_lng = 0.0;
double fence_radius = 0.0;

// For timestamp
const long gmtOffset_sec = 5 * 3600 + 1800; // +5:30 in seconds
const int daylightOffset_sec = 0;

// Helper: Calculate distance between two GPS coordinates in meters (Haversine formula)
double haversine(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371000.0; // Earth radius in meters
  double dLat = radians(lat2 - lat1);
  double dLon = radians(lon2 - lon1);
  double a = sin(dLat/2) * sin(dLat/2) +
             cos(radians(lat1)) * cos(radians(lat2)) *
             sin(dLon/2) * sin(dLon/2);
  double c = 2 * atan2(sqrt(a), sqrt(1-a));
  return R * c;
}

// Helper: Get current timestamp as string in Asia/Colombo time (+5:30)
String getLocalTimestamp() {
  time_t now = time(nullptr);
  struct tm timeinfo;
  gmtime_r(&now, &timeinfo); // Get UTC
  time_t local = now + gmtOffset_sec;
  gmtime_r(&local, &timeinfo);
  char buf[32];
  strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &timeinfo);
  return String(buf);
}

// Download geofence from Firestore (Proper JSON parsing)
void fetchGeofence() {
  String url = String(FIRESTORE_HOST) + GEOFENCE_PATH;
  HTTPClient http;
  http.begin(url);
  int httpCode = http.GET();
  if (httpCode == 200) {
    String payload = http.getString();
    StaticJsonDocument<1024> doc;
    DeserializationError error = deserializeJson(doc, payload);
    if (!error) {
      JsonObject fields = doc["fields"];
      // latitude
      if (fields.containsKey("latitude")) {
        if (fields["latitude"].containsKey("doubleValue")) {
          fence_lat = fields["latitude"]["doubleValue"].as<double>();
        } else if (fields["latitude"].containsKey("integerValue")) {
          fence_lat = fields["latitude"]["integerValue"].as<double>();
        }
      }
      // longitude
      if (fields.containsKey("longitude")) {
        if (fields["longitude"].containsKey("doubleValue")) {
          fence_lng = fields["longitude"]["doubleValue"].as<double>();
        } else if (fields["longitude"].containsKey("integerValue")) {
          fence_lng = fields["longitude"]["integerValue"].as<double>();
        }
      }
      // radius
      if (fields.containsKey("radius")) {
        if (fields["radius"].containsKey("doubleValue")) {
          fence_radius = fields["radius"]["doubleValue"].as<double>();
        } else if (fields["radius"].containsKey("integerValue")) {
          fence_radius = fields["radius"]["integerValue"].as<double>();
        }
      }
      Serial.print("Geofence fetched: lat=");
      Serial.print(fence_lat, 6);
      Serial.print(" lng=");
      Serial.print(fence_lng, 6);
      Serial.print(" radius=");
      Serial.println(fence_radius);
    } else {
      Serial.println("Failed to parse geofence JSON!");
    }
  } else {
    Serial.print("Failed to fetch geofence, code: ");
    Serial.println(httpCode);
  }
  http.end();
}

// Send a history event to Firestore (FIXED: POST to collection, not document)
void sendHistoryEvent(const char* eventType, double lat, double lng) {
  String url = String(FIRESTORE_HOST) + HISTORY_PATH; // POST to collection endpoint!
  String json = "{\"fields\":{";
  json += "\"event\":{\"stringValue\":\"" + String(eventType) + "\"},";
  json += "\"timestamp\":{\"stringValue\":\"" + getLocalTimestamp() + "\"},";
  json += "\"latitude\":{\"doubleValue\":" + String(lat, 6) + "},";
  json += "\"longitude\":{\"doubleValue\":" + String(lng, 6) + "}";
  json += "}}";
  HTTPClient http;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  int httpCode = http.POST(json);
  Serial.print("[Firestore] History event (");
  Serial.print(eventType);
  Serial.print(") HTTP code: ");
  Serial.println(httpCode);
  Serial.println(http.getString()); // Print server response for debugging
  http.end();
}

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);
  mlx.begin();
  GPSSerial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500); Serial.print(".");
  }
  Serial.println("\nWiFi connected!");

  // Set up NTP for timestamp (Asia/Colombo, +5:30)
  configTime(gmtOffset_sec, daylightOffset_sec, "pool.ntp.org", "time.nist.gov");

  delay(2000); // Wait for NTP

  fetchGeofence(); // Get geofence on startup
}

void loop() {
  // --- GPS Read ---
  while (GPSSerial.available()) {
    char c = GPSSerial.read();
    gps.encode(c);
  }

  // Update last known GPS location if new data is available
  double lat = last_lat;
  double lng = last_lng;
  bool location_changed = false;
  if (gps.location.isValid() && gps.location.isUpdated()) {
    lat = gps.location.lat();
    lng = gps.location.lng();
    if (lat != last_lat || lng != last_lng) {
      last_lat = lat;
      last_lng = lng;
      location_changed = true;
    }
  }

  // --- Temp Read ---
  float object_temp = mlx.readObjectTempC();
  bool temp_changed = (object_temp != last_object_temp);
  if (temp_changed) {
    last_object_temp = object_temp;
  }

  // --- Firestore PATCH for location ---
  if (location_changed && WiFi.status() == WL_CONNECTED) {
    String url = String(FIRESTORE_HOST) + LOCATION_PATH + "?updateMask.fieldPaths=latitude&updateMask.fieldPaths=longitude";
    String json = "{\"fields\":{";
    json += "\"latitude\":{\"doubleValue\":" + String(lat, 6) + "},";
    json += "\"longitude\":{\"doubleValue\":" + String(lng, 6) + "}";
    json += "}}";
    HTTPClient http;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    int httpCode = http.PATCH(json);
    Serial.print("[Firestore] Location update HTTP code: ");
    Serial.println(httpCode);
    http.end();
  }

  // --- Firestore PATCH for temperature ---
  if (temp_changed && WiFi.status() == WL_CONNECTED) {
    String url = String(FIRESTORE_HOST) + TEMPERATURE_PATH + "?updateMask.fieldPaths=temp";
    String json = "{\"fields\":{";
    json += "\"temp\":{\"doubleValue\":" + String(object_temp, 2) + "}";
    json += "}}";
    HTTPClient http;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    int httpCode = http.PATCH(json);
    Serial.print("[Firestore] Temperature update HTTP code: ");
    Serial.println(httpCode);
    http.end();
  }

  // --- Geofence Check ---
  if (fence_radius > 0.0 && gps.location.isValid()) {
    double distance = haversine(lat, lng, fence_lat, fence_lng);
    bool inside = (distance <= fence_radius);

    if (inside && !was_inside_geofence) {
      Serial.println("[GEOFENCE] Dog has ENTERED the geofence.");
      sendHistoryEvent("entered", lat, lng);
      was_inside_geofence = true;
    } else if (!inside && was_inside_geofence) {
      Serial.println("[GEOFENCE] Dog has LEFT the geofence!");
      sendHistoryEvent("left", lat, lng);
      was_inside_geofence = false;
    }
  }

  static unsigned long last_geofence_fetch = 0;
  if (millis() - last_geofence_fetch > 60000) { // Refresh geofence every minute
    fetchGeofence();
    last_geofence_fetch = millis();
  }

  delay(3000); // Main loop every 3 seconds
}