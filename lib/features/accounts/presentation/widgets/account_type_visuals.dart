import 'package:flutter/material.dart';
import 'package:jeb/features/accounts/domain/entities/account_type.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Icon + accent color for each [AccountType], kept out of the domain layer.
abstract final class AccountTypeVisuals {
  const AccountTypeVisuals._();

  static IconData icon(AccountType type) => switch (type) {
        AccountType.cash => PhosphorIcons.money(PhosphorIconsStyle.duotone),
        AccountType.bank => PhosphorIcons.bank(PhosphorIconsStyle.duotone),
        AccountType.card =>
          PhosphorIcons.creditCard(PhosphorIconsStyle.duotone),
        AccountType.wallet => PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
        AccountType.other =>
          PhosphorIcons.piggyBank(PhosphorIconsStyle.duotone),
      };

  static Color color(AccountType type) => switch (type) {
        AccountType.cash => const Color(0xFF16A34A), // green
        AccountType.bank => const Color(0xFF2563EB), // blue
        AccountType.card => const Color(0xFF7C3AED), // violet
        AccountType.wallet => const Color(0xFFEA580C), // orange
        AccountType.other => const Color(0xFF0891B2), // cyan
      };
}
