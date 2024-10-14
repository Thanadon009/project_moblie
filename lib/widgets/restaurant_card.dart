import 'package:flutter/material.dart';

import '../models/restaurant_model.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.network(restaurant.imageUrl),
        title: Text(restaurant.name),
        subtitle: Text('Rating: ${restaurant.rating}'),
      ),
    );
  }
}
