import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _plugin.initialize(initializationSettings);
  }

  // lib/utils/notification_helper.dart
  static Future<void> showDogOutNotification({String? title, String? body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dog_out_channel',
      'Dog Out of Geofence',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      0,
      title ?? 'Dog Alert',
      body ?? '⚠️ Your dog is out of the geofence area!',
      details,
    );
  }
}