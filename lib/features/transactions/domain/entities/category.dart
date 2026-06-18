import 'package:equatable/equatable.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

/// A spending/income category. Icon and color are stored as primitives so the
/// domain layer stays free of Flutter dependencies.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.type,
  });

  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final TransactionType type;

  @override
  List<Object?> get props => [id, name, iconCodePoint, colorValue, type];
}
