import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../models/geofence_model.dart';
import '../widgets/map_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? currentLocation;
  double radius = 100.0;

  Future<void> _setGeofence() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      final geofence = Geofence(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: radius,
      );
      await FirestoreService.saveGeofence(geofence);
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geofence saved successfully!')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _setGeofence();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PAWHUB')),
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: MapWidget(
                    center: currentLocation!,
                    radius: radius,
                  ),
                ),
                Slider(
                  min: 50,
                  max: 500,
                  divisions: 9,
                  value: radius,
                  label: '${radius.round()} m',
                  onChanged: (value) => setState(() => radius = value),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Geofence"),
                  onPressed: _setGeofence,
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
