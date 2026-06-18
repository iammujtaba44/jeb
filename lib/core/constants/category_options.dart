import 'package:flutter/material.dart';

/// Selectable icons and colors offered when creating/editing a category.
abstract final class CategoryOptions {
  const CategoryOptions._();

  static const List<IconData> icons = <IconData>[
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.receipt_long,
    Icons.favorite,
    Icons.movie,
    Icons.local_cafe,
    Icons.flight,
    Icons.home_outlined,
    Icons.fitness_center,
    Icons.school_outlined,
    Icons.pets,
    Icons.medical_services_outlined,
    Icons.phone_android,
    Icons.wifi,
    Icons.local_gas_station_outlined,
    Icons.card_giftcard,
    Icons.sports_esports,
    Icons.payments_outlined,
    Icons.work_outline,
    Icons.savings_outlined,
    Icons.bolt,
    Icons.train_outlined,
    Icons.local_bar_outlined,
    Icons.child_care,
    Icons.book_outlined,
    Icons.category_outlined,
  ];

  static const List<int> colors = <int>[
    0xFFEF6C00,
    0xFF2E7D32,
    0xFF1565C0,
    0xFF6A1B9A,
    0xFFC62828,
    0xFFAD1457,
    0xFF3949AB,
    0xFF6D4C41,
    0xFF00838F,
    0xFF607D8B,
    0xFF1A936F,
    0xFF00897B,
    0xFF7CB342,
    0xFFF59E0B,
    0xFFD81B60,
    0xFF5E35B1,
  ];
}
