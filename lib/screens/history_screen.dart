import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence History'),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
      ),
      body: StreamBuilder<List<HistoryEvent>>(
        stream: FirestoreService.streamHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return Center(
              child: Text(
                "No geofence history available.",
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final e = events[i];
              final isEntered = e.event == 'entered';
              final color = isEntered ? Colors.green[700] : Colors.red[700];
              final icon = isEntered
                  ? Icons.login
                  : Icons.logout;
              final subtitle = "Lat: ${e.latitude.toStringAsFixed(6)},  Lng: ${e.longitude.toStringAsFixed(6)}";
              final timeStr = DateFormat("yyyy-MM-dd HH:mm:ss").format(e.timestamp);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color!.withOpacity(0.3), width: 1),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  title: Text(
                    isEntered ? "Dog entered geofence" : "Dog left geofence",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subtitle),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}