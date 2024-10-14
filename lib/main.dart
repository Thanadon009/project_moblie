import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'screens/comments_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/review_form_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _setupNotifications(); // ตั้งค่าช่องการแจ้งเตือน
  runApp(MyApp());
}

Future<void> _setupNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ตั้งค่าช่องการแจ้งเตือน
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'your_channel_id', // ID ของช่อง
    'your_channel_name', // ชื่อช่อง
    description: 'Your channel description',
    importance: Importance.max,
    playSound: true,
  );

  // สร้างช่องการแจ้งเตือน
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // สร้าง instance ของ FirebaseAuth
    final firebaseAuth = FirebaseAuth.instance;
    final firebaseFirestore = FirebaseFirestore.instance;
    return MaterialApp(
      title: 'Yoi Yoii',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: LoginScreen(
          firebaseAuth: firebaseAuth), // ส่ง firebaseAuth ไปยัง LoginScreen
      routes: {
        '/home': (context) => HomeScreen(firestore: firebaseFirestore),
        '/profile': (context) => ProfileScreen(),
        '/comments': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return CommentsScreen(reviewId: args['reviewId']);
        },
        '/notification': (context) => NotificationScreen(),
        '/login': (context) => LoginScreen(
            firebaseAuth: firebaseAuth), // ส่ง firebaseAuth ให้ LoginScreen
        '/register': (context) => RegisterScreen(),
        '/review_form': (context) => ReviewFormScreen(auth: firebaseAuth),
      },
    );
  }
}

// ฟังก์ชันส่งการแจ้งเตือน
Future<void> _sendNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id', // ID ของช่อง
    'your_channel_name', // ชื่อช่อง
    channelDescription: 'Your channel description',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // ID ของ Notification
    title,
    body,
    platformChannelSpecifics,
    payload: 'item x', // ข้อมูลเพิ่มเติม (ถ้าต้องการ)
  );
}
