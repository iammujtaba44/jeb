import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/account_type.dart';

final class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.type,
    required super.currencyCode,
    required this.updatedAt,
    super.openingBalance,
    super.note,
    super.archived,
    this.isDeleted = false,
  });

  final DateTime updatedAt;
  final bool isDeleted;

  factory AccountModel.fromEntity(Account a, {required DateTime updatedAt}) {
    return AccountModel(
      id: a.id,
      name: a.name,
      type: a.type,
      currencyCode: a.currencyCode,
      openingBalance: a.openingBalance,
      note: a.note,
      archived: a.archived,
      updatedAt: updatedAt,
    );
  }

  factory AccountModel.fromMap(DataMap map) {
    return AccountModel(
      id: map[DbConstants.columnId] as String,
      name: map[DbConstants.columnName] as String,
      type: AccountType.fromStorage(map[DbConstants.columnType] as String),
      currencyCode: map[DbConstants.columnCurrencyCode] as String,
      openingBalance:
          (map[DbConstants.columnOpeningBalance] as num?)?.toDouble() ?? 0,
      note: map[DbConstants.columnNote] as String?,
      archived: (map[DbConstants.columnArchived] as int? ?? 0) == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnUpdatedAt] as int,
      ),
      isDeleted: (map[DbConstants.columnIsDeleted] as int) == 1,
    );
  }

  DataMap toMap() => <String, dynamic>{
        DbConstants.columnId: id,
        DbConstants.columnName: name,
        DbConstants.columnType: type.storageValue,
        DbConstants.columnCurrencyCode: currencyCode,
        DbConstants.columnOpeningBalance: openingBalance,
        DbConstants.columnNote: note,
        DbConstants.columnArchived: archived ? 1 : 0,
        DbConstants.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
        DbConstants.columnIsDeleted: isDeleted ? 1 : 0,
      };
}
