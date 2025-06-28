import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/geofence_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Geofence ---
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

  // --- Dog location ---
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

  // --- Temperature stream ---
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

  // --- Vaccinations ---
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

  // --- HISTORY ---

  /// Stream all history events, ordered by timestamp descending (most recent first)
  static Stream<List<HistoryEvent>> streamHistory({String? filterEvent}) {
    Query query = _db.collection('history').orderBy('timestamp', descending: true);
    if (filterEvent != null) {
      query = query.where('event', isEqualTo: filterEvent);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => HistoryEvent.fromFirestore(doc)).toList());
  }
}

/// Model for a single history event
class HistoryEvent {
  final String id;
  final String event; // 'entered' or 'left'
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  HistoryEvent({
    required this.id,
    required this.event,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  factory HistoryEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Timestamp field may be string or Timestamp
    DateTime ts;
    if (data['timestamp'] is Timestamp) {
      ts = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      ts = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }
    return HistoryEvent(
      id: doc.id,
      event: data['event'] ?? '',
      timestamp: ts,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}