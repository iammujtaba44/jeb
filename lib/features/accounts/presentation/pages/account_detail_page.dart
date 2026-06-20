import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_colors.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';
import 'package:jeb/features/accounts/domain/usecases/accounts_usecases.dart';
import 'package:jeb/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:jeb/features/accounts/presentation/pages/account_editor_page.dart';
import 'package:jeb/features/accounts/presentation/widgets/account_type_visuals.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/presentation/widgets/category_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Shows one account: its current balance and a unified history of the
/// transactions assigned to it plus the transfers in and out.
class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({required this.accountId, super.key});

  final String accountId;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  List<Transaction> _transactions = const <Transaction>[];
  Map<String, Category> _categoriesById = const <String, Category>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txnResult =
        await getIt<GetAccountTransactions>()(widget.accountId);
    final catResult = await getIt<GetCategories>()(const NoParams());
    if (!mounted) return;
    setState(() {
      _transactions = txnResult.fold(
        (_) => const <Transaction>[],
        (List<Transaction> t) => t,
      );
      _categoriesById = catResult.fold(
        (_) => const <String, Category>{},
        (List<Category> c) => <String, Category>{
          for (final Category cat in c) cat.id: cat,
        },
      );
      _loading = false;
    });
  }

  Future<void> _edit(BuildContext context, Account account) async {
    final AccountsCubit cubit = context.read<AccountsCubit>();
    final String currency =
        context.read<SettingsCubit>().state.settings.defaultCurrencyCode;
    final Account? updated = await Navigator.of(context).push<Account>(
      MaterialPageRoute<Account>(
        builder: (_) => AccountEditorPage(
          defaultCurrency: currency,
          existing: account,
        ),
      ),
    );
    if (updated != null) await cubit.saveAccount(updated);
  }

  Future<void> _delete(BuildContext context, Account account) async {
    final AccountsCubit cubit = context.read<AccountsCubit>();
    final NavigatorState navigator = Navigator.of(context);
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
    if (ok ?? false) {
      await cubit.deleteAccount(account.id);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (BuildContext context, AccountsState state) {
        final Account? account = state.accountById(widget.accountId);
        if (account == null) {
          return const Scaffold(
            body: Center(child: Text('Account not found')),
          );
        }
        final List<Transfer> transfers = state.transfers
            .where((Transfer t) =>
                t.fromAccountId == account.id || t.toAccountId == account.id)
            .toList();
        final List<_Item> items = _merge(_transactions, transfers);

        return Scaffold(
          appBar: AppBar(
            title: Text(account.name),
            actions: <Widget>[
              IconButton(
                icon: Icon(PhosphorIcons.pencilSimple()),
                tooltip: 'Edit',
                onPressed: () => _edit(context, account),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.trash()),
                tooltip: 'Delete',
                onPressed: () => _delete(context, account),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                _BalanceHeader(
                  account: account,
                  balance: state.balanceFor(account),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel('History'),
                const SizedBox(height: AppSpacing.sm),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No activity yet. Assign transactions to this account '
                        'or transfer money in.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < items.length; i++) ...<Widget>[
                          if (i > 0) const Divider(height: 1, indent: 64),
                          _itemTile(context, items[i], account, state),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemTile(
    BuildContext context,
    _Item item,
    Account account,
    AccountsState state,
  ) {
    return switch (item) {
      _TxnItem(:final Transaction transaction) => _TransactionRow(
          transaction: transaction,
          category: _categoriesById[transaction.categoryId],
        ),
      _TransferItem(:final Transfer transfer) => _TransferRow(
          transfer: transfer,
          account: account,
          other: state.accountById(
            transfer.fromAccountId == account.id
                ? transfer.toAccountId
                : transfer.fromAccountId,
          ),
        ),
    };
  }
}

/// Merge transactions and transfers into one date-descending history.
List<_Item> _merge(List<Transaction> txns, List<Transfer> transfers) {
  final List<_Item> items = <_Item>[
    for (final Transaction t in txns) _TxnItem(t),
    for (final Transfer t in transfers) _TransferItem(t),
  ];
  items.sort((_Item a, _Item b) => b.date.compareTo(a.date));
  return items;
}

sealed class _Item {
  const _Item();
  DateTime get date;
}

final class _TxnItem extends _Item {
  const _TxnItem(this.transaction);
  final Transaction transaction;
  @override
  DateTime get date => transaction.date;
}

final class _TransferItem extends _Item {
  const _TransferItem(this.transfer);
  final Transfer transfer;
  @override
  DateTime get date => transfer.date;
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.account, required this.balance});

  final Account account;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color color = AccountTypeVisuals.color(account.type);
    final bool negative = balance < 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.18), color),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(AccountTypeVisuals.icon(account.type),
                  color: Colors.white, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                account.type.label,
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Current balance',
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${negative ? '-' : ''}'
            '${MoneyFormatter.compact(balance.abs(), account.currencyCode)}',
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.category});

  final Transaction transaction;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final bool isExpense = transaction.type == TransactionType.expense;
    final Color color = isExpense ? AppColors.expense : AppColors.income;
    final String sign = isExpense ? '-' : '+';
    final String subtitle = transaction.note?.isNotEmpty ?? false
        ? transaction.note!
        : DateFormatter.dayMonth(transaction.date);

    return ListTile(
      leading: category == null
          ? const Icon(Icons.help_outline)
          : CategoryAvatar(category: category!),
      title: Text(category?.name ?? 'Uncategorized'),
      subtitle: Text(subtitle),
      trailing: Text(
        '$sign${MoneyFormatter.compact(transaction.amount, transaction.currencyCode)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.account,
    required this.other,
  });

  final Transfer transfer;
  final Account account;
  final Account? other;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool outgoing = transfer.fromAccountId == account.id;
    final String sign = outgoing ? '-' : '+';
    final Color color = outgoing ? AppColors.expense : AppColors.income;
    final String otherName = other?.name ?? 'Deleted';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(
          PhosphorIcons.arrowsLeftRight(),
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
      ),
      title: Text(outgoing ? 'Transfer to $otherName' : 'Transfer from $otherName'),
      subtitle: Text(DateFormatter.dayMonth(transfer.date)),
      trailing: Text(
        '$sign${MoneyFormatter.compact(transfer.amount, account.currencyCode)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
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
