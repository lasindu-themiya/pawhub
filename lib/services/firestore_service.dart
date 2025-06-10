import 'package:cloud_firestore/cloud_firestore.dart';
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
}
