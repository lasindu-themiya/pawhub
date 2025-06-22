import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final LatLng center;
  final double radius;
  final LatLng? dogLocation;

  const MapWidget({
    super.key,
    required this.center,
    required this.radius,
    this.dogLocation,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.pawhub',
        ),
        MarkerLayer(
          markers: [
            // Geofence center marker (optional, can remove if not needed)
            Marker(
              point: center,
              width: 30,
              height: 30,
              child: const Icon(Icons.location_on, color: Colors.blue, size: 30),
            ),
            // Dog location marker
            if (dogLocation != null)
              Marker(
                point: dogLocation!,
                width: 40,
                height: 40,
                child: const Icon(Icons.pets, color: Colors.brown, size: 36),
              ),
          ],
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radius,
              useRadiusInMeter: true,
              color: Colors.blue.withOpacity(0.2),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
            ),
          ],
        ),
      ],
    );
  }
}