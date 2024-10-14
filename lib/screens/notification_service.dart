import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // ไอคอนสำหรับการแจ้งเตือน

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '333', // เปลี่ยนเป็น ID ของ Channel ที่คุณต้องการ
      '111', // เปลี่ยนเป็นชื่อ Channel ที่คุณต้องการ
      channelDescription:
          'This channel is used for general notifications.', // เปลี่ยนเป็นคำอธิบายของ Channel
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0, // ID ของการแจ้งเตือน
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x', // ข้อมูลเพิ่มเติม (ถ้าต้องการ)
    );
  }
}
