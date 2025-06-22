import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../models/geofence_model.dart';
import '../widgets/map_widget.dart';
import '../utils/notification_helper.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  LatLng? _center;
  double _radius = 100;
  bool _loading = true;
  bool _saving = false;
  String? _locationError;
  bool _geofenceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadGeofenceOrLocation();
  }

  Future<void> _loadGeofenceOrLocation() async {
    setState(() {
      _loading = true;
      _locationError = null;
    });
    try {
      final geofence = await FirestoreService.fetchGeofence();
      if (geofence != null) {
        setState(() {
          _center = LatLng(geofence.latitude, geofence.longitude);
          _radius = geofence.radius;
          _loading = false;
          _geofenceLoaded = true;
        });
      } else {
        await _initLocationForNewGeofence();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _locationError = e.toString();
      });
    }
  }

  Future<void> _initLocationForNewGeofence() async {
    // Request location permission
    final status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() {
        _loading = false;
        _locationError = "Location permission denied. Please enable it in settings.";
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Please enable it in settings.'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
      return;
    }

    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _radius = 100;
        _loading = false;
        _geofenceLoaded = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _locationError = e.toString();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().toLowerCase().contains('location services are disabled')
                    ? 'Location is turned off. Please enable location services.'
                    : 'Error getting location: $e',
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  Future<void> _addNewGeofence() async {
    setState(() {
      _loading = true;
      _locationError = null;
    });
    await _initLocationForNewGeofence();
  }

  void _checkDogInGeofenceWithNotification(LatLng? dogLocation) {
    if (_center == null || dogLocation == null) return;
    final distance = Distance().as(LengthUnit.Meter, _center!, dogLocation);
    final isOut = distance > _radius;
    if (isOut) {
      NotificationHelper.showDogOutNotification();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Dog is out of the geofence area!'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  Future<void> _saveGeofence() async {
    if (_center == null) return;
    setState(() => _saving = true);
    final geofence = Geofence(
      latitude: _center!.latitude,
      longitude: _center!.longitude,
      radius: _radius,
    );
    await FirestoreService.saveGeofence(geofence);
    setState(() {
      _saving = false;
      _geofenceLoaded = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geofence saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_center == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Location & Geofence"),
          backgroundColor: Colors.blue[700],
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                _locationError?.toLowerCase().contains('location services are disabled') == true
                    ? "Location is turned off.\nPlease enable location services and try again."
                    : _locationError ?? "Failed to get location.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadGeofenceOrLocation,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Location & Geofence"),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Geofence',
            onPressed: _loadGeofenceOrLocation,
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            tooltip: 'Add New Geofence',
            onPressed: _addNewGeofence,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('location')
            .doc('dog_location')
            .snapshots(),
        builder: (context, snapshot) {
          LatLng? dogLocation;
          if (snapshot.hasData && snapshot.data!.data() != null) {
            final data = snapshot.data!.data()!;
            if (data['latitude'] != null && data['longitude'] != null) {
              dogLocation = LatLng(data['latitude'], data['longitude']);
            }
          }
          // Check geofence and notify if needed
          _checkDogInGeofenceWithNotification(dogLocation);

          return Column(
            children: [
              Expanded(
                child: MapWidget(
                  center: _center!,
                  radius: _radius,
                  dogLocation: dogLocation,
                ),
              ),
              if (dogLocation != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pets, color: Colors.brown, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Dog: Lat ${dogLocation.latitude.toStringAsFixed(6)}, '
                        'Lng ${dogLocation.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Radius: ${_radius.toStringAsFixed(0)} meters",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Slider(
                      min: 50,
                      max: 500,
                      divisions: 9,
                      value: _radius,
                      label: "${_radius.toStringAsFixed(0)} m",
                      onChanged: (value) {
                        setState(() {
                          _radius = value;
                        });
                      },
                      activeColor: Colors.blue[700],
                      inactiveColor: Colors.blue[100],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveGeofence,
                      icon: const Icon(Icons.save),
                      label: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Save Geofence"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}