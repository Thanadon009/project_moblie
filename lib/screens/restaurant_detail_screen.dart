import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final String restaurantId;

  RestaurantDetailScreen({required this.restaurantId});

  Future<String> getImageUrl(String imagePath) async {
    return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Restaurant Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var restaurant = snapshot.data!;
          return Column(
            children: [
              FutureBuilder<String>(
                future: getImageUrl(restaurant['imagePath']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  return Image.network(snapshot.data!);
                },
              ),
              Text(restaurant['name']),
              Text(restaurant['description']),
              // Add more restaurant details
            ],
          );
        },
      ),
    );
  }
}
