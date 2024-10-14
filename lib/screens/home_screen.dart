import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseFirestore firestore;
  HomeScreen({Key? key, required this.firestore}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? _profileImageUrl;
  int selectedRating = -1;
  List<String> bookmarkedReviews = []; // สร้างตัวแปรสำหรับเก็บรีวิวที่ถูกบันทึก
  int _currentIndex = 0; // ตัวแปรสำหรับติดตามหน้าปัจจุบัน
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadBookmarkedReviews(); // โหลดรีวิวที่ถูกบันทึก
  }

  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _profileImageUrl = doc['photoURL'];
        });
      }
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }

  Future<void> _loadBookmarkedReviews() async {
    try {
      QuerySnapshot bookmarkSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('bookmarks')
          .get();
      setState(() {
        bookmarkedReviews = bookmarkSnapshot.docs
            .map((doc) => doc['reviewId'] as String)
            .toList();
      });
    } catch (e) {
      print('Failed to load bookmarked reviews: $e');
    }
  }

  Future<void> _bookmarkReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('bookmarks')
          .doc(reviewId)
          .set({
        'reviewId': reviewId,
      });
      setState(() {
        bookmarkedReviews.add(reviewId); // เพิ่มรีวิวที่ถูกบันทึกลงในลิสต์
      });
      print('Review $reviewId bookmarked successfully!');
    } catch (e) {
      print('Failed to bookmark review: $e');
    }
  }

  Future<void> _removeBookmark(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('bookmarks')
          .doc(reviewId)
          .delete();
      setState(() {
        bookmarkedReviews.remove(reviewId); // ลบรีวิวที่ถูกบันทึกออกจากลิสต์
      });
      print('Review $reviewId unbookmarked successfully!');
    } catch (e) {
      print('Failed to remove bookmark: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      Navigator.pushNamed(context, '/profile');
    } else if (index == 0) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 231, 127, 15),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo3.png',
              height: 70,
            ),
            SizedBox(width: 8),
            Text(
              'Yoi Yoii',
              style: TextStyle(
                fontFamily: 'STXingkai',
                color:
                    const Color.fromARGB(255, 0, 0, 0), // เปลี่ยนสีฟอนต์ที่นี่
                fontSize: 24, // ปรับขนาดฟอนต์ถ้าต้องการ
                fontWeight: FontWeight.bold, // ปรับน้ำหนักฟอนต์ถ้าต้องการ
              ),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, '/notification');
            },
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 238, 238, 238),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/review_form');
              },
              child: Container(
                margin: EdgeInsets.all(16.0),
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 231, 127, 15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: _profileImageUrl != null
                          ? MemoryImage(base64Decode(_profileImageUrl!))
                          : AssetImage('assets/default_profile.jpg')
                              as ImageProvider,
                    ),
                    Expanded(
                      child: Text(
                        'คุณกำลังคิดอะไรอยู่?',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  int rating = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        // ถ้ากดดาวที่เลือกอยู่แล้ว ให้ยกเลิกการเลือก
                        selectedRating = selectedRating == rating ? -1 : rating;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: selectedRating == rating
                            ? const Color.fromARGB(255, 154, 86, 47)
                            : const Color.fromARGB(255, 231, 127, 15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          Text('$rating'),
                          Icon(
                            Icons.star,
                            size: 16,
                            color: selectedRating == rating
                                ? Colors.yellow
                                : const Color.fromARGB(255, 255, 255,
                                    255), // เปลี่ยนสีของดาวที่เลือกเป็นสีเหลือง และสีของดาวที่ไม่ได้เลือกเป็นสีเทา
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedRating == -1
                    ? FirebaseFirestore.instance
                        .collection('reviews')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('reviews')
                        .where('rating', isEqualTo: selectedRating)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('ไม่มีรีวิว'));
                  }

                  var reviews = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      var review = reviews[index];
                      var reviewData = review.data() as Map<String, dynamic>?;

                      if (reviewData == null ||
                          !reviewData.containsKey('review')) {
                        return Container(
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ข้อมูลไม่สมบูรณ์',
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          ),
                        );
                      }

                      List<Uint8List> imageBytesList = [];
                      if (reviewData.containsKey('images') &&
                          reviewData['images'] is List) {
                        for (String image in reviewData['images']) {
                          if (image.isNotEmpty) {
                            try {
                              Uint8List imageBytes = base64Decode(image);
                              imageBytesList.add(imageBytes);
                            } catch (e) {
                              print('Error decoding Base64: $e');
                            }
                          }
                        }
                      }

                      bool isBookmarked = bookmarkedReviews.contains(review.id);

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(reviewData['userId'])
                            .get(),
                        builder: (context, userSnapshot) {
                          Uint8List? userImageBytes;
                          String displayName =
                              'ผู้ใช้ไม่รู้จัก'; // ชื่อเริ่มต้น

                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (userSnapshot.hasData &&
                              userSnapshot.data!.exists) {
                            var userData = userSnapshot.data!.data()
                                as Map<String, dynamic>;
                            displayName =
                                userData['displayName'] ?? displayName;
                            if (userData['photoURL'] != null) {
                              try {
                                userImageBytes =
                                    base64Decode(userData['photoURL']);
                              } catch (e) {
                                print('Error decoding Base64: $e');
                              }
                            }
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/comments',
                                arguments: {
                                  'reviewId': review.id,
                                },
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 1,
                                  horizontal: 3), // ลดระยะห่างระหว่างกรอบโพส
                              padding:
                                  EdgeInsets.all(14), // ปรับ padding ตามต้องการ
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(
                                    color: const Color.fromARGB(
                                        255, 238, 238, 238)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: userImageBytes != null
                                            ? MemoryImage(userImageBytes)
                                            : AssetImage(
                                                    'assets/default_profile.jpg')
                                                as ImageProvider,
                                        radius: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    reviewData['review'],
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  if (imageBytesList.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ImageDetailScreen(
                                                    imageBytesList:
                                                        imageBytesList),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 100,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: imageBytesList.length,
                                          itemBuilder: (context, imgIndex) {
                                            return Container(
                                              margin: EdgeInsets.only(right: 8),
                                              child: Image.memory(
                                                imageBytesList[imgIndex],
                                                width: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'คะแนนรีวิว :',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 8),
                                      Row(
                                        children: List.generate(5, (index) {
                                          return Icon(
                                            index < reviewData['rating']
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: const Color.fromARGB(
                                                255, 255, 238, 0),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'วันที่: ${review['timestamp'].toDate().toLocal().day.toString().padLeft(2, '0')}-${review['timestamp'].toDate().toLocal().month.toString().padLeft(2, '0')}-${review['timestamp'].toDate().toLocal().year} เวลา: ${review['timestamp'].toDate().toLocal().hour.toString().padLeft(2, '0')}:${review['timestamp'].toDate().toLocal().minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (isBookmarked) {
                                            _removeBookmark(review.id);
                                          } else {
                                            _bookmarkReview(review.id);
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              isBookmarked
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                              color: isBookmarked
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                            SizedBox(width: 4),
                                            Text(isBookmarked
                                                ? 'Unbookmark'
                                                : 'Bookmark'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color.fromARGB(255, 231, 127,
            15), // เปลี่ยนสีพื้นหลังของ BottomNavigationBar ที่นี่
        selectedItemColor:
            const Color.fromARGB(255, 0, 0, 0), // สีของไอคอนที่เลือก
        unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

class ImageDetailScreen extends StatelessWidget {
  final List<Uint8List> imageBytesList;

  const ImageDetailScreen({Key? key, required this.imageBytesList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // PageController สำหรับควบคุม PageView
    PageController pageController = PageController();

    return Scaffold(
      appBar: AppBar(
        title: Text('ภาพรีวิว'),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: imageBytesList.length,
            itemBuilder: (context, index) {
              return Center(
                child: Image.memory(
                  imageBytesList[index],
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
          // ปุ่มเลื่อนไปข้างหน้า
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 25,
            child: IconButton(
              icon: Icon(Icons.arrow_forward, size: 30),
              onPressed: () {
                if (pageController.hasClients) {
                  pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
          // ปุ่มเลื่อนถอยหลัง
          Positioned(
            left: 16,
            top: MediaQuery.of(context).size.height / 2 - 25,
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 30),
              onPressed: () {
                if (pageController.hasClients) {
                  pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
