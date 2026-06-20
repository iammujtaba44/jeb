/// The kind of wallet an [Account] represents — drives its default icon and
/// helps the user tell cash apart from a bank or card at a glance.
enum AccountType {
  cash,
  bank,
  card,
  wallet,
  other;

  String get storageValue => name;

  static AccountType fromStorage(String value) => AccountType.values.firstWhere(
        (AccountType t) => t.name == value,
        orElse: () => AccountType.cash,
      );

  String get label => switch (this) {
        AccountType.cash => 'Cash',
        AccountType.bank => 'Bank',
        AccountType.card => 'Card',
        AccountType.wallet => 'Wallet',
        AccountType.other => 'Other',
      };
}
