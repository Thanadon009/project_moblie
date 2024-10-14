import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReviewFormScreen extends StatefulWidget {
  final FirebaseAuth auth; // เพิ่มตัวแปรนี้

  // แก้ไข constructor
  ReviewFormScreen({Key? key, required this.auth}) : super(key: key);

  @override
  _ReviewFormScreenState createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  List<XFile>? _imageFiles = []; // เปลี่ยนเป็น List เพื่อรองรับหลายรูป
  final _picker = ImagePicker();
  double _selectedRating = 3.0; // Default rating value

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      print('Form is valid.');

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      print('User ID: $userId');
      if (userId == null) {
        print('User is not logged in.');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('User is not logged in.')));
        return;
      }

      List<String> base64Images = []; // ใช้ List เพื่อเก็บ Base64 String ของรูป

      for (var imageFile in _imageFiles!) {
        print('Image file selected');
        final bytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(bytes); // Convert image to Base64
        base64Images.add(base64Image); // เพิ่ม Base64 String ลงใน List
        print('Base64 Image length: ${base64Image.length}');
      }

      // Show review data before submitting to Firestore
      print('Review Data:');
      print('User ID: $userId');
      print('Review Text: ${_reviewController.text}');
      print('Base64 Images Count: ${base64Images.length}');
      print('Rating: $_selectedRating');

      try {
        print('Attempting to add review to Firestore...');
        // Create a new review document and get its reference
        DocumentReference reviewRef =
            await FirebaseFirestore.instance.collection('reviews').add({
          'userId': userId,
          'review': _reviewController.text,
          'images': base64Images, // เก็บ List ของ Base64 String
          'rating': _selectedRating,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update the document to include the reviewId
        await reviewRef.update({'reviewId': reviewRef.id});

        print('Review submitted successfully with ID: ${reviewRef.id}');

        // Show Snackbar to inform success
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Review submitted successfully.')));

        // Navigate back to Home
        Navigator.pop(context);
      } catch (e) {
        print('Error submitting review: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting review: $e')));
      }
    } else {
      print('Form is not valid.');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill out all fields correctly.')));
    }
  }

  // ฟังก์ชันสำหรับสร้าง Widget ดาว
  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.toInt(); // จำนวนดาวเต็ม

    // สร้างดาวเต็ม
    for (int i = 0; i < fullStars; i++) {
      stars
          .add(Icon(Icons.star, color: const Color.fromARGB(255, 242, 218, 0)));
    }

    // สร้างดาวว่าง
    for (int i = stars.length; i < 5; i++) {
      stars.add(Icon(Icons.star_border,
          color: const Color.fromARGB(255, 245, 193, 6)));
    }

    return Row(children: stars); // ส่งกลับเป็น Row ที่มีดาว
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 238, 238, 238),
        appBar: AppBar(
          title: Text('Review Form'),
          backgroundColor: const Color.fromARGB(255, 231, 127, 15),
          actions: [
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _submitReview, // Post action
            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context); // Cancel action
            },
          ),
        ),
        body: Container(
          color: const Color.fromARGB(255, 238, 238, 238), // เปลี่ยนสีที่นี่
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Review input
                    TextFormField(
                      controller: _reviewController,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your status';
                        }
                        return null;
                      },
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),

                    // Display selected images if available
                    if (_imageFiles!.isNotEmpty)
                      Column(
                        children: _imageFiles!.asMap().entries.map((entry) {
                          int index = entry.key;
                          XFile imageFile = entry.value;
                          return FutureBuilder<Uint8List>(
                            future: imageFile.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  height: 250,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _imageFiles!.removeAt(
                                                  index); // ลบรูปที่เลือก
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return Container(
                                  height: 150,
                                  color: Colors.grey[300], // Placeholder
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),

                    // Buttons for Camera and Photo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Camera button
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_imageFiles!.length < 5) {
                              // เช็คจำนวนรูป
                              XFile? image = await _picker.pickImage(
                                  source: ImageSource.camera);
                              if (image != null) {
                                setState(() {
                                  _imageFiles!.add(image); // เพิ่มรูปลงใน List
                                });
                                print('Image Path: ${_imageFiles?.last.path}');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('No image selected')));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'You can upload up to 5 images.')));
                            }
                          },
                          icon: Icon(Icons.camera_alt),
                          label: Text('Camera'),
                        ),
                        // Photo button
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_imageFiles!.length < 5) {
                              // เช็คจำนวนรูป
                              XFile? image = await _picker.pickImage(
                                  source: ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  _imageFiles!.add(image); // เพิ่มรูปลงใน List
                                });
                                print('Image Path: ${_imageFiles?.last.path}');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('No image selected')));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'You can upload up to 5 images.')));
                            }
                          },
                          icon: Icon(Icons.photo),
                          label: Text('Photo'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // Rating using stars
                    Text('Rating:'), // Header for rating
                    _buildRatingStars(_selectedRating), // Show stars for rating
                    Slider(
                      value: _selectedRating,
                      min: 1.0,
                      max: 5.0,
                      divisions: 4, // Allow increments of 1 (1, 2, 3, 4, 5)
                      label: _selectedRating
                          .toStringAsFixed(0), // Display whole number
                      onChanged: (value) {
                        setState(() {
                          _selectedRating =
                              value; // Update rating on slider change
                        });
                      },
                    ),
                    SizedBox(height: 10),

                    // Submit button
                    ElevatedButton(
                      onPressed: _submitReview,
                      child: Center(child: Text('Post Review')),
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            Size(double.infinity, 40), // Full width button
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
