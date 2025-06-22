class Geofence {
  final double latitude;
  final double longitude;
  final double radius;

  Geofence({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      };

  factory Geofence.fromJson(Map<String, dynamic> json) {
    return Geofence(
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'],
    );
  }
}