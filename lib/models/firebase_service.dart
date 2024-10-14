import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/restaurant_model.dart'; // นำเข้า Restaurant Model

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // เก็บตัวแปรไว้สำหรับใช้งาน

  Future<User?> signInWithEmail(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  // ฟังก์ชันสำหรับดึงข้อมูลร้านอาหารจาก Firestore
  Future<List<Restaurant>> getRestaurants() async {
    QuerySnapshot snapshot = await _firestore.collection('restaurants').get();
    return snapshot.docs.map((doc) {
      return Restaurant.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // เพิ่มฟังก์ชันสำหรับเพิ่มหรือแก้ไขข้อมูลร้านอาหาร
  Future<void> addRestaurant(Restaurant restaurant) async {
    await _firestore.collection('restaurants').add({
      'name': restaurant.name,
      'imageUrl': restaurant.imageUrl,
      'rating': restaurant.rating,
    });
  }
}
