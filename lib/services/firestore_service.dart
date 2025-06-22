import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/geofence_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> saveGeofence(Geofence geofence) async {
    await _db.collection('geofence').doc('dogFence').set(geofence.toJson());
  }

  static Future<Geofence?> fetchGeofence() async {
    final doc = await _db.collection('geofence').doc('dogFence').get();
    if (doc.exists) {
      return Geofence.fromJson(doc.data()!);
    }
    return null;
  }

  static Future<LatLng?> fetchDogLocation() async {
    final doc = await _db.collection('location').doc('dog_location').get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['latitude'] != null && data['longitude'] != null) {
        return LatLng(data['latitude'], data['longitude']);
      }
    }
    return null;
  }

  // --- Stream the current temperature from 'temperature/dogtemp' ---
  static Stream<double?> streamCurrentTemperature() {
    return _db
        .collection('temperature')
        .doc('dogtemp')
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data != null && data['temp'] != null) {
            return (data['temp'] as num).toDouble();
          }
          return null;
        });
  }

  // --- Vaccination methods for a single dog ---
  // Structure: vaccinations (collection) -> dog (doc) -> records (subcollection)
  static Stream<List<Map<String, dynamic>>> streamVaccinations() {
    return _db
        .collection('vaccinations')
        .doc('dog')
        .collection('records')
        .orderBy('nextDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'type': data['type'],
                'date': data['date'],
                'duration': data['duration'],
                'nextDate': data['nextDate'],
              };
            }).toList());
  }

  static Future<void> addVaccination({
    required String type,
    required DateTime date,
    required int duration,
  }) async {
    // Calculate next vaccination date
    final nextDate = DateTime(date.year, date.month + duration, date.day);
    await _db
        .collection('vaccinations')
        .doc('dog')
        .collection('records')
        .add({
      'type': type,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'nextDate': Timestamp.fromDate(nextDate),
    });
  }

  // ...existing code...

  static Future<void> deleteVaccination(String docId) async {
    await _db
        .collection('vaccinations')
        .doc('dog')
        .collection('records')
        .doc(docId)
        .delete();
  }

  static Future<void> updateVaccination({
    required String docId,
    required String type,
    required DateTime date,
    required int duration,
  }) async {
    final nextDate = DateTime(date.year, date.month + duration, date.day);
    await _db
        .collection('vaccinations')
        .doc('dog')
        .collection('records')
        .doc(docId)
        .update({
      'type': type,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'nextDate': Timestamp.fromDate(nextDate),
    });
  }
}