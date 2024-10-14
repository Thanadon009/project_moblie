import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CommentsScreen extends StatefulWidget {
  final String reviewId;

  CommentsScreen({required this.reviewId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  TextEditingController commentController = TextEditingController();

  String _posterName = 'ไม่ทราบชื่อ';
  Uint8List? _posterImageBytes;
  String _posterId = '';

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();

    _loadReviewDetails();
    _listenForNewComments();
  }

  Future<void> _initializeLocalNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadReviewDetails() async {
    try {
      DocumentSnapshot reviewDoc = await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.reviewId)
          .get();

      if (reviewDoc.exists && reviewDoc.data() != null) {
        var reviewData = reviewDoc.data() as Map<String, dynamic>;
        _posterId = reviewData['userId'];

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_posterId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            _posterName = userDoc['displayName'] ?? 'ไม่ทราบชื่อ';
            String? base64Image = userDoc['photoURL'];
            if (base64Image != null && base64Image.isNotEmpty) {
              if (base64Image.startsWith('data:image/')) {
                base64Image = base64Image.split(',')[1];
              }
              _posterImageBytes = base64Decode(base64Image);
            }
          });
        }
      }
    } catch (e) {
      print('Failed to load review details: $e');
    }
  }

  void _listenForNewComments() {
    FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.reviewId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((commentSnapshot) {
      if (commentSnapshot.docChanges.isNotEmpty) {
        for (var change in commentSnapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            var newCommentData = change.doc.data() as Map<String, dynamic>?;

            if (newCommentData != null) {
              String userId = newCommentData['userId'];
              _sendNotification(
                  'New Comment', '$userId added to the review.', userId);
            }
          }
        }
      }
    });
  }

  Future<void> _sendNotification(
      String title, String body, String posterId) async {
    print(
        'Sending Notification: title = $title, body = $body, posterId = $posterId');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '333',
      '111',
      channelDescription: 'This channel is used for general notifications.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: posterId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('คอมเมนต์'),
          backgroundColor: const Color.fromARGB(255, 231, 127, 15),
        ),
        body: Container(
            color: const Color.fromARGB(255, 238, 238, 238),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(widget.reviewId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text('ไม่พบรีวิวนี้'));
                }

                var reviewData = snapshot.data!.data() as Map<String, dynamic>?;

                if (reviewData == null) {
                  return Center(child: Text('ข้อมูลไม่สมบูรณ์'));
                }

                List<Uint8List> imageBytesList = [];
                if (reviewData.containsKey('images') &&
                    reviewData['images'] is List) {
                  for (String base64Image in reviewData['images']) {
                    if (base64Image.isNotEmpty) {
                      imageBytesList.add(base64Decode(base64Image));
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: _posterImageBytes != null
                                ? MemoryImage(_posterImageBytes!)
                                : null,
                            radius: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            _posterName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        reviewData['review'] ?? 'ไม่มีข้อความรีวิว',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      if (imageBytesList.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: imageBytesList.map((imageBytes) {
                            return GestureDetector(
                              onTap: () {
                                // เปิดหน้าจอแสดงรูปภาพ
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageScreen(
                                      imageBytes: imageBytes,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.memory(
                                  imageBytes,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('reviews')
                              .doc(widget.reviewId)
                              .collection('comments')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, commentSnapshot) {
                            if (commentSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (!commentSnapshot.hasData ||
                                commentSnapshot.data!.docs.isEmpty) {
                              return Center(child: Text('ยังไม่มีคอมเมนต์'));
                            }

                            var comments = commentSnapshot.data!.docs;

                            return ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                var commentData = comments[index].data()
                                    as Map<String, dynamic>?;

                                String userId = commentData?['userId'] ?? '';
                                String commentId = comments[index].id;

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }

                                    if (!userSnapshot.hasData ||
                                        !userSnapshot.data!.exists) {
                                      return Center(
                                          child: Text('ไม่พบข้อมูลผู้ใช้'));
                                    }

                                    var userData = userSnapshot.data!.data()
                                        as Map<String, dynamic>?;

                                    Uint8List? userProfileImageBytes;
                                    String userDisplayName =
                                        userData?['displayName'] ??
                                            'ไม่ทราบชื่อ';
                                    String? base64Image = userData?['photoURL'];
                                    if (base64Image != null &&
                                        base64Image.isNotEmpty) {
                                      if (base64Image
                                          .startsWith('data:image/')) {
                                        base64Image = base64Image.split(',')[1];
                                      }
                                      userProfileImageBytes =
                                          base64Decode(base64Image);
                                    }

                                    return Container(
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      padding: EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 223, 223, 223),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage:
                                                userProfileImageBytes != null
                                                    ? MemoryImage(
                                                        userProfileImageBytes)
                                                    : null,
                                            radius: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userDisplayName,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  commentData?['comment'] ??
                                                      'ไม่มีข้อความคอมเมนต์',
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () {
                                              _deleteComment(commentId);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          labelText: 'แสดงความคิดเห็น...',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () {
                              _postComment();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )));
  }

  Future<void> _postComment() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String comment = commentController.text.trim();

    if (comment.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.reviewId)
          .collection('comments')
          .add({
        'userId': userId,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      commentController.clear();
    } catch (e) {
      print('Error posting comment: $e');
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.reviewId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }
}

class ImageScreen extends StatelessWidget {
  final Uint8List imageBytes;

  ImageScreen({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รูปภาพ'),
      ),
      body: Center(
        child: Image.memory(imageBytes),
      ),
    );
  }
}
