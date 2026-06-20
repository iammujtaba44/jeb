import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:jeb/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:jeb/features/accounts/presentation/pages/accounts_page.dart';
import 'package:jeb/features/accounts/presentation/widgets/account_type_visuals.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A horizontal, swipeable strip of account balances for the home dashboard.
/// Requires an [AccountsCubit] ancestor; renders nothing until there are
/// accounts to show.
class AccountsCarousel extends StatelessWidget {
  const AccountsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (BuildContext context, AccountsState state) {
        if (state.isLoading || state.accounts.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _CarouselHeader(
              icon: PhosphorIcons.wallet(PhosphorIconsStyle.fill),
              title: 'Accounts',
              trailing: MoneyFormatter.compact(state.totalNet, state.currency),
              onSeeAll: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const AccountsPage()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: state.accounts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (BuildContext context, int index) {
                  final Account account = state.accounts[index];
                  return _AccountChip(
                    account: account,
                    balance: state.balanceFor(account),
                    onTap: () => _openDetail(context, account),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  void _openDetail(BuildContext context, Account account) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<AccountsCubit>.value(
          value: context.read<AccountsCubit>(),
          child: AccountDetailPage(accountId: account.id),
        ),
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.account,
    required this.balance,
    required this.onTap,
  });

  final Account account;
  final double balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = AccountTypeVisuals.color(account.type);
    final bool negative = balance < 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(AccountTypeVisuals.icon(account.type),
                    color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  MoneyFormatter.compact(balance, account.currencyCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: negative ? scheme.error : null,
                  ),
                ),
                Text(
                  account.type.label,
                  style: textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselHeader extends StatelessWidget {
  const _CarouselHeader({
    required this.icon,
    required this.title,
    required this.onSeeAll,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.sm, 0),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Text(
              trailing!,
              style: textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all'),
          ),
        ],
      ),
    );
  }
}
