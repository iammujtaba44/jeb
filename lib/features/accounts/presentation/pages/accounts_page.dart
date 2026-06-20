import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/core/widgets/icon_badge.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';
import 'package:jeb/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:jeb/features/accounts/presentation/pages/account_editor_page.dart';
import 'package:jeb/features/accounts/presentation/pages/transfer_editor_page.dart';
import 'package:jeb/features/accounts/presentation/widgets/account_type_visuals.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountsCubit>(
      create: (_) => getIt<AccountsCubit>()..load(),
      child: const AccountsView(),
    );
  }
}

class AccountsView extends StatelessWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New account',
            onPressed: () => _newAccount(context),
          ),
        ],
      ),
      body: BlocBuilder<AccountsCubit, AccountsState>(
        builder: (BuildContext context, AccountsState state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isEmpty) return const _EmptyState();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              _TotalCard(state: state),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonalIcon(
                onPressed: state.canTransfer ? () => _transfer(context) : null,
                icon: Icon(PhosphorIcons.arrowsLeftRight()),
                label: const Text('Transfer between accounts'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final Account account in state.accounts) ...<Widget>[
                _AccountCard(
                  account: account,
                  balance: state.balanceFor(account),
                  onTap: () => _editAccount(context, account),
                  onDelete: () => _confirmDeleteAccount(context, account),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (state.transfers.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                const _SectionLabel('Recent transfers'),
                const SizedBox(height: AppSpacing.sm),
                for (final Transfer t in state.transfers.take(8))
                  _TransferTile(
                    transfer: t,
                    state: state,
                    onDelete: () => _confirmDeleteTransfer(context, t),
                  ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  String _currency(BuildContext context) =>
      context.read<SettingsCubit>().state.settings.defaultCurrencyCode;

  Future<void> _newAccount(BuildContext context) async {
    final AccountsCubit cubit = context.read<AccountsCubit>();
    final String currency = _currency(context);
    final Account? account = await Navigator.of(context).push<Account>(
      MaterialPageRoute<Account>(
        builder: (_) => AccountEditorPage(defaultCurrency: currency),
      ),
    );
    if (account != null) await cubit.saveAccount(account);
  }

  Future<void> _editAccount(BuildContext context, Account existing) async {
    final AccountsCubit cubit = context.read<AccountsCubit>();
    final String currency = _currency(context);
    final Account? account = await Navigator.of(context).push<Account>(
      MaterialPageRoute<Account>(
        builder: (_) => AccountEditorPage(
          defaultCurrency: currency,
          existing: existing,
        ),
      ),
    );
    if (account != null) await cubit.saveAccount(account);
  }

  Future<void> _transfer(BuildContext context) async {
    final AccountsCubit cubit = context.read<AccountsCubit>();
    final Transfer? transfer = await Navigator.of(context).push<Transfer>(
      MaterialPageRoute<Transfer>(
        builder: (_) => TransferEditorPage(accounts: cubit.state.accounts),
      ),
    );
    if (transfer != null) await cubit.addTransfer(transfer);
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    Account account,
  ) async {
    final AccountsCubit cubit = context.read<AccountsCubit>();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Delete ${account.name}?'),
        content: const Text(
          'The account and its transfers are removed. Transactions you logged '
          'against it are kept but become unassigned.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok ?? false) await cubit.deleteAccount(account.id);
  }

  Future<void> _confirmDeleteTransfer(
    BuildContext context,
    Transfer transfer,
  ) async {
    final AccountsCubit cubit = context.read<AccountsCubit>();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete transfer?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok ?? false) await cubit.deleteTransfer(transfer.id);
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.state});

  final AccountsState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool positive = state.totalNet >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            Color.alphaBlend(
              scheme.tertiary.withValues(alpha: 0.45),
              scheme.primary,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Total balance',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${positive ? '' : '-'}'
            '${MoneyFormatter.compact(state.totalNet.abs(), state.currency)}',
            style: textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Across ${state.accounts.length} '
            '${state.accounts.length == 1 ? 'account' : 'accounts'}',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.balance,
    required this.onTap,
    required this.onDelete,
  });

  final Account account;
  final double balance;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = AccountTypeVisuals.color(account.type);
    final bool negative = balance < 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        onLongPress: onDelete,
        leading: IconBadge(
          icon: AccountTypeVisuals.icon(account.type),
          color: color,
        ),
        title: Text(
          account.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(account.type.label),
        trailing: Text(
          MoneyFormatter.compact(balance, account.currencyCode),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: negative ? scheme.error : null,
          ),
        ),
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.transfer,
    required this.state,
    required this.onDelete,
  });

  final Transfer transfer;
  final AccountsState state;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Account? from = state.accountById(transfer.fromAccountId);
    final Account? to = state.accountById(transfer.toAccountId);
    final String fromName = from?.name ?? 'Deleted';
    final String toName = to?.name ?? 'Deleted';
    final String currency = from?.currencyCode ?? state.currency;

    return ListTile(
      dense: true,
      onLongPress: onDelete,
      leading: Icon(
        PhosphorIcons.arrowsLeftRight(),
        color: scheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text('$fromName → $toName'),
      subtitle: Text(DateFormatter.dayMonth(transfer.date)),
      trailing: Text(
        MoneyFormatter.compact(transfer.amount, currency),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
              size: 56,
              color: scheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No accounts yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add your cash, bank, and card balances to see where your money '
              'lives and move it between wallets. Tap + to add one.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
