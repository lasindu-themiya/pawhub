const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

// Always use the same document for the single owner
const OWNER_DOC = "owner"; // Firestore path: users/owner

// Haversine formula to calculate distance between two lat/lng points in meters
function haversine(lat1, lon1, lat2, lon2) {
  function toRad(x) { return x * Math.PI / 180; }
  const R = 6371000;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

// Helper to check geofence and update history if needed
async function checkAndUpdateHistory() {
  // Get latest location
  const locDoc = await admin.firestore().collection('location').doc('dog_location').get();
  if (!locDoc.exists) return;
  const loc = locDoc.data();

  // Get latest geofence
  const fenceDoc = await admin.firestore().collection('geofence').doc('dogFence').get();
  if (!fenceDoc.exists) return;
  const fence = fenceDoc.data();

  const centerLat = fence.latitude;
  const centerLng = fence.longitude;
  const radius = fence.radius;

  const dist = haversine(loc.latitude, loc.longitude, centerLat, centerLng);
  const nowState = dist > radius ? 'outside' : 'inside';

  // Get last known state
  const statusRef = admin.firestore().collection('status').doc('dog_status');
  const statusDoc = await statusRef.get();
  const lastState = statusDoc.exists ? statusDoc.data().state : null;

  // Only add history if state changed
  if (lastState !== nowState) {
    const eventType = nowState === 'outside' ? 'left' : 'entered';
    const now = new Date();
    // Format timestamp as "YYYY-MM-DD HH:mm:ss"
    const formattedTimestamp = now.toISOString().replace('T', ' ').substring(0, 19);
    await admin.firestore().collection('history').add({
      event: eventType,
      timestamp: formattedTimestamp,
      latitude: loc.latitude,
      longitude: loc.longitude,
    });
    await statusRef.set({ state: nowState }, { merge: true });
  }
}

// Trigger on location update
exports.checkGeofenceOnLocationUpdate = functions.firestore
  .document('location/dog_location')
  .onUpdate(async (change, context) => {
    await checkAndUpdateHistory();
    return null;
  });

// Trigger on geofence update
exports.checkGeofenceOnGeofenceUpdate = functions.firestore
  .document('geofence/dogFence')
  .onUpdate(async (change, context) => {
    await checkAndUpdateHistory();
    return null;
  });

// Notify when dog leaves geofence
exports.notifyOnGeofenceEvent = functions.firestore
  .document('history/{eventId}')
  .onCreate(async (snap, context) => {
    const event = snap.data();
    if (event.event === 'left') {
      const userDoc = await admin.firestore().collection('users').doc(OWNER_DOC).get();
      const fcmToken = userDoc.data() && userDoc.data().fcmToken;
      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: 'Dog left the geofence!',
            body: 'Your dog left the safe area. Check the map for the last location.',
          },
        });
      }
    }
  });

// Notify when temperature is High or Dangerously High
exports.notifyOnTemperatureEvent = functions.firestore
  .document('temperature/dogtemp')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const temp = after.temp;
    let title = null;
    let body = null;

    if (typeof temp === "number") {
      if (temp > 41.1) {
        title = "Dangerously High Temperature!";
        body = `🚨 Your dog's temperature is dangerously high: ${temp}°C`;
      } else if (temp > 39.4) {
        title = "High Temperature Alert";
        body = `⚠️ Your dog's temperature is high: ${temp}°C`;
      }
    }

    if (title && body) {
      const userDoc = await admin.firestore().collection('users').doc(OWNER_DOC).get();
      const fcmToken = userDoc.data() && userDoc.data().fcmToken;
      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: title,
            body: body,
          },
        });
      }
    }
  });