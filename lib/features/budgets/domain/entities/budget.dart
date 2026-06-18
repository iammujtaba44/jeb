import 'package:equatable/equatable.dart';

/// A monthly spending limit. A null [categoryId] means the overall budget;
/// otherwise it is the limit for that category. Amounts are in the user's
/// home currency.
class Budget extends Equatable {
  const Budget({required this.categoryId, required this.limitAmount});

  final String? categoryId;
  final double limitAmount;

  bool get isOverall => categoryId == null;

  @override
  List<Object?> get props => [categoryId, limitAmount];
}
