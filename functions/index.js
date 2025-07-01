const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

// Always use the same document for the single owner
const OWNER_DOC = "owner"; // Firestore path: users/owner

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