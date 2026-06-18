import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

/// Data-layer representation of a [Category] (+ sync metadata).
final class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.iconCodePoint,
    required super.colorValue,
    required super.type,
    required this.updatedAt,
    this.isDeleted = false,
  });

  final DateTime updatedAt;
  final bool isDeleted;

  factory CategoryModel.fromMap(DataMap map) {
    return CategoryModel(
      id: map[DbConstants.columnId] as String,
      name: map[DbConstants.columnName] as String,
      iconCodePoint: map[DbConstants.columnIconCodePoint] as int,
      colorValue: map[DbConstants.columnColorValue] as int,
      type: TransactionType.fromStorage(map[DbConstants.columnType] as String),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnUpdatedAt] as int,
      ),
      isDeleted: (map[DbConstants.columnIsDeleted] as int) == 1,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      DbConstants.columnId: id,
      DbConstants.columnName: name,
      DbConstants.columnIconCodePoint: iconCodePoint,
      DbConstants.columnColorValue: colorValue,
      DbConstants.columnType: type.storageValue,
      DbConstants.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
      DbConstants.columnIsDeleted: isDeleted ? 1 : 0,
    };
  }
}
