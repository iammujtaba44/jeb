import 'package:equatable/equatable.dart';
import 'package:jeb/features/accounts/domain/entities/account_type.dart';

/// A place money lives — cash on hand, a bank account, a card, or a wallet.
/// Its running balance is [openingBalance] adjusted by the transactions
/// assigned to it and the transfers in and out.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currencyCode,
    this.openingBalance = 0,
    this.note,
    this.archived = false,
  });

  final String id;
  final String name;
  final AccountType type;
  final String currencyCode;

  /// The balance the account already held when it was first added.
  final double openingBalance;

  final String? note;

  /// Hidden from the main list and from totals without being deleted.
  final bool archived;

  Account copyWith({
    String? name,
    AccountType? type,
    String? currencyCode,
    double? openingBalance,
    String? note,
    bool? archived,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      openingBalance: openingBalance ?? this.openingBalance,
      note: note ?? this.note,
      archived: archived ?? this.archived,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        type,
        currencyCode,
        openingBalance,
        note,
        archived,
      ];
}
