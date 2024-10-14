import 'dart:convert'; // เพิ่มการนำเข้า dart:convert
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'comments_screen.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<NotificationItem> notifications = []; // รายการการแจ้งเตือน

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
      String? payload = notificationResponse.payload;
      if (payload != null) {
        print('Notification payload: $payload');
      }
    });

    _requestPermission();
    _listenForNewPosts();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '333',
      '111',
      channelDescription: 'This channel is used for general notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  void _listenForNewPosts() {
    FirebaseFirestore.instance
        .collection('reviews')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final reviewData = doc.doc.data() as Map<String, dynamic>;
          final userId = reviewData['userId'];

          // ตรวจสอบว่าโพสต์นี้คือโพสต์ของผู้ใช้งานคนปัจจุบันหรือไม่
          final currentUserId =
              _auth.currentUser?.uid; // รับ userId ของผู้ใช้งานคนปัจจุบัน
          if (currentUserId != null && currentUserId != userId) {
            _getUserInfo(userId).then((userInfo) {
              final message = ' ได้โพสต์รีวิวใหม่';
              // รับ timestamp จาก Firestore
              final Timestamp timestamp = reviewData['timestamp'];
              // แปลง timestamp เป็นเวลาที่อ่านได้
              final String formattedTimestamp = _formatTimestamp(timestamp);

              _showNotification('โพสต์ใหม่', message);
              notifications.add(NotificationItem(
                user: userInfo['displayName'] ?? 'ผู้ใช้ไม่รู้จัก',
                message: message,
                timestamp: formattedTimestamp, // ใช้เวลาที่แปลงแล้ว
                imageUrl: userInfo['photoURL'] ?? '',
                reviewId: doc.doc.id, // เพิ่ม reviewId ที่นี่
              ));
              setState(() {}); // อัปเดต UI
            });
          }
        }
      }
    });
  }

  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data()
            as Map<String, dynamic>; // คืนค่าข้อมูลผู้ใช้ทั้งหมด
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
    return {
      'displayName': 'ผู้ใช้ไม่รู้จัก',
      'photoURL': '', // แก้ไขให้เป็นว่างเปล่า
    };
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    // ปรับรูปแบบวันที่ตามที่คุณต้องการ
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('การแจ้งเตือน'),
        backgroundColor: const Color.fromARGB(255, 231, 127, 15),
      ),
      body: Container(
        color: const Color.fromARGB(255, 238, 238, 238),
        child: notifications.isEmpty
            ? Center(child: Text('ไม่มีการแจ้งเตือน'))
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return NotificationCard(
                    notification: notifications[index],
                    reviewId: notifications[index].reviewId, // เพิ่ม reviewId
                  );
                },
              ),
      ),
    );
  }
}

class NotificationItem {
  final String user;
  final String message;
  final String timestamp; // เก็บ timestamp แบบ String
  final String imageUrl;
  final String reviewId; // เพิ่ม reviewId

  NotificationItem({
    required this.user,
    required this.message,
    required this.timestamp,
    required this.imageUrl,
    required this.reviewId, // เพิ่มใน constructor
  });
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final String reviewId;

  NotificationCard({required this.notification, required this.reviewId});

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (notification.imageUrl.isNotEmpty) {
      imageBytes = base64Decode(notification.imageUrl);
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: imageBytes != null
              ? MemoryImage(imageBytes)
              : AssetImage('assets/default_profile.jpg') as ImageProvider,
        ),
        title: Text('${notification.user} ${notification.message}'),
        subtitle: Text(notification.timestamp),
        trailing: Icon(Icons.notifications),
        onTap: () {
          // นำทางไปยังหน้า comments_screen พร้อมส่ง reviewId
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommentsScreen(reviewId: reviewId),
            ),
          );
        },
      ),
    );
  }
}
