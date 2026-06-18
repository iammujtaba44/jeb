import 'package:flutter/material.dart';
import 'package:jeb/features/transactions/data/models/category_model.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

/// The categories seeded into a fresh database. Stable ids keep cloud sync
/// consistent across devices. Icon/color values live here (config), never
/// scattered through the UI.
abstract final class DefaultCategories {
  const DefaultCategories._();

  static final DateTime _seededAt = DateTime.fromMillisecondsSinceEpoch(0);

  static List<CategoryModel> seed() => <CategoryModel>[
        _expense('food', 'Food', Icons.restaurant, 0xFFEF6C00),
        _expense('groceries', 'Groceries', Icons.shopping_cart, 0xFF2E7D32),
        _expense('transport', 'Transport', Icons.directions_car, 0xFF1565C0),
        _expense('shopping', 'Shopping', Icons.shopping_bag, 0xFF6A1B9A),
        _expense('bills', 'Bills', Icons.receipt_long, 0xFFC62828),
        _expense('health', 'Health', Icons.favorite, 0xFFAD1457),
        _expense('fun', 'Entertainment', Icons.movie, 0xFF3949AB),
        _expense('coffee', 'Coffee', Icons.local_cafe, 0xFF6D4C41),
        _expense('travel', 'Travel', Icons.flight, 0xFF00838F),
        _expense('other_expense', 'Other', Icons.category, 0xFF607D8B),
        _income('salary', 'Salary', Icons.payments, 0xFF1A936F),
        _income('freelance', 'Freelance', Icons.work, 0xFF00897B),
        _income('other_income', 'Other Income', Icons.savings, 0xFF7CB342),
      ];

  static CategoryModel _expense(
    String id,
    String name,
    IconData icon,
    int color,
  ) {
    return CategoryModel(
      id: id,
      name: name,
      iconCodePoint: icon.codePoint,
      colorValue: color,
      type: TransactionType.expense,
      updatedAt: _seededAt,
    );
  }

  static CategoryModel _income(
    String id,
    String name,
    IconData icon,
    int color,
  ) {
    return CategoryModel(
      id: id,
      name: name,
      iconCodePoint: icon.codePoint,
      colorValue: color,
      type: TransactionType.income,
      updatedAt: _seededAt,
    );
  }
}
