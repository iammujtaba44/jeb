import 'package:flutter/material.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';

/// Circular icon badge for a category, colored from the category's own color.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    required this.category,
    this.radius = 22,
    super.key,
  });

  final Category category;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(category.colorValue);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(
        IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
        color: color,
        size: radius,
      ),
    );
  }
}
