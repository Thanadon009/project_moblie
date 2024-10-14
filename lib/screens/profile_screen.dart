import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project2/screens/comments_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  final ImagePicker _picker = ImagePicker();
  String? _profileImageUrl;
  late TabController _tabController;
  List<Map<String, dynamic>> bookmarks = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
    _checkAndCreateUserDocument();
    _loadUserProfile();
    _loadBookmarks();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _checkAndCreateUserDocument() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
    if (!doc.exists) {
      await createUserDocument(user!);
    }
  }

  Future<void> createUserDocument(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
      });
      print('User document created successfully!');
    } catch (e) {
      print('Failed to create user document: $e');
    }
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

  Future<void> _loadBookmarks() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('bookmarks')
          .get();

      List<Map<String, dynamic>> loadedBookmarks = [];
      for (var doc in snapshot.docs) {
        var reviewId = doc['reviewId'];
        var reviewSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .doc(reviewId)
            .get();
        if (reviewSnapshot.exists) {
          loadedBookmarks.add({
            'id': reviewSnapshot.id,
            ...reviewSnapshot.data() as Map<String, dynamic>,
          });
        }
      }

      setState(() {
        bookmarks = loadedBookmarks;
      });
    } catch (e) {
      print('Failed to load bookmarks: $e');
    }
  }

  Future<void> _pickImage() async {
    XFile? pickedFile;

    try {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        await _uploadImage(pickedFile);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _uploadImage(XFile pickedFile) async {
    try {
      final bytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({'photoURL': base64Image});

      setState(() {
        _profileImageUrl = base64Image;
      });

      await _loadUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      print('Failed to upload image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  Future<void> _updateProfileName() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({'displayName': _nameController.text});
      await user?.updateProfile(displayName: _nameController.text);
      await user?.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully!')),
      );
    } catch (e) {
      print('Failed to update name: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    } catch (e) {
      print('Logout failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: const Color.fromARGB(255, 231, 127, 15),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: Container(
          color: const Color.fromARGB(255, 238, 238, 238),
          child: Column(
            children: [
              SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImageUrl != null
                      ? MemoryImage(base64Decode(_profileImageUrl!))
                      : AssetImage('assets/default_profile.jpg')
                          as ImageProvider,
                  child: _profileImageUrl == null
                      ? Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Welcome',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _isEditing
                  ? TextField(
                      controller: _nameController,
                      decoration:
                          InputDecoration(labelText: 'Change your name'),
                    )
                  : Text(
                      user?.displayName ?? 'Name Lastname',
                      style: TextStyle(fontSize: 18),
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_isEditing) {
                    _updateProfileName();
                  }
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                child: Text(_isEditing ? 'Save' : 'Edit Name'),
              ),
              SizedBox(height: 20),
              Container(
                color: const Color.fromARGB(255, 231, 127, 15),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: const Color.fromARGB(255, 0, 0, 0),
                  indicatorColor: Colors.black,
                  tabs: [
                    Tab(text: 'My Post'),
                    Tab(text: 'Bookmark'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reviews')
                          .where('userId', isEqualTo: user?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        var reviews = snapshot.data!.docs;
                        if (reviews.isEmpty) {
                          return Center(child: Text('No posts found'));
                        }
                        return ListView.builder(
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            var review = reviews[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // แสดงรูปภาพในแนวนอน
                                  if (review['images'] != null)
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: List.from(review['images']
                                            .map((image) => Container(
                                                  margin:
                                                      EdgeInsets.only(right: 8),
                                                  child: Image.memory(
                                                    base64Decode(image),
                                                    fit: BoxFit.cover,
                                                    height: 100, // ขนาดสูง
                                                    width: 100, // ขนาดกว้าง
                                                  ),
                                                ))),
                                      ),
                                    ),
                                  ListTile(
                                    title: Text(review['review']),
                                    subtitle: Text(
                                      'วันที่: ${review['timestamp'].toDate().toLocal().day}-${review['timestamp'].toDate().toLocal().month}-${review['timestamp'].toDate().toLocal().year} เวลา: ${review['timestamp'].toDate().toLocal().hour}:${review['timestamp'].toDate().toLocal().minute}',
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CommentsScreen(
                                              reviewId: review.id),
                                        ),
                                      );
                                    },
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('reviews')
                                            .doc(review.id)
                                            .delete();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('Post deleted')),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    bookmarks.isNotEmpty
                        ? ListView.builder(
                            itemCount: bookmarks.length,
                            itemBuilder: (context, index) {
                              var bookmark = bookmarks[index];
                              return Card(
                                margin: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // แสดงรูปภาพในแนวนอน
                                    if (bookmark['images'] != null)
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: List.from(bookmark['images']
                                              .map((image) => Container(
                                                    margin: EdgeInsets.only(
                                                        right: 8),
                                                    child: Image.memory(
                                                      base64Decode(image),
                                                      fit: BoxFit.cover,
                                                      height: 100, // ขนาดสูง
                                                      width: 100, // ขนาดกว้าง
                                                    ),
                                                  ))),
                                        ),
                                      ),
                                    ListTile(
                                      title: Text(bookmark['review']),
                                      subtitle: Text(
                                        'วันที่: ${bookmark['timestamp'].toDate().toLocal().day}-${bookmark['timestamp'].toDate().toLocal().month}-${bookmark['timestamp'].toDate().toLocal().year} เวลา: ${bookmark['timestamp'].toDate().toLocal().hour}:${bookmark['timestamp'].toDate().toLocal().minute}',
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CommentsScreen(
                                                    reviewId: bookmark['id']),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(child: Text('No bookmarks found')),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
