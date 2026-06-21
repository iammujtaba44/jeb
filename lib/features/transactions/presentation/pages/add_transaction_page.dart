import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/core/widgets/app_snackbar.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';
import 'package:jeb/features/transactions/presentation/widgets/amount_currency_field.dart';
import 'package:jeb/features/transactions/presentation/widgets/category_selector.dart';
import 'package:jeb/features/transactions/presentation/widgets/date_picker_tile.dart';
import 'package:jeb/features/transactions/presentation/widgets/note_input_field.dart';
import 'package:jeb/features/transactions/presentation/widgets/receipt_section.dart';
import 'package:jeb/features/transactions/presentation/widgets/repeat_section.dart';
import 'package:jeb/features/transactions/presentation/widgets/save_transaction_button.dart';
import 'package:jeb/features/transactions/presentation/widgets/transaction_type_selector.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Add a new transaction, or edit an existing one when [transaction] is given.
class AddTransactionPage extends StatelessWidget {
  const AddTransactionPage({
    required this.categories,
    required this.defaultCurrency,
    this.transaction,
    super.key,
  });

  final List<Category> categories;
  final String defaultCurrency;
  final Transaction? transaction;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddTransactionCubit>(
      create: (_) => getIt<AddTransactionCubit>()
        ..loadAccounts()
        ..initialize(existing: transaction, defaultCurrency: defaultCurrency),
      child: AddTransactionView(
        categories: categories,
        isEditing: transaction != null,
        initialAmount: transaction?.amount,
        initialNote: transaction?.note,
      ),
    );
  }
}

class AddTransactionView extends StatelessWidget {
  const AddTransactionView({
    required this.categories,
    required this.isEditing,
    this.initialAmount,
    this.initialNote,
    super.key,
  });

  final List<Category> categories;
  final bool isEditing;
  final double? initialAmount;
  final String? initialNote;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddTransactionCubit, AddTransactionState>(
      listenWhen: (AddTransactionState prev, AddTransactionState curr) =>
          prev.status != curr.status,
      listener: _onStatusChanged,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: <Widget>[
                  AmountCurrencyField(initialAmount: initialAmount),
                  const _ConversionHint(),
                  const SizedBox(height: AppSpacing.lg),
                  const SizedBox(
                    width: double.infinity,
                    child: TransactionTypeSelector(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _FieldLabel(text: 'Category'),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: CategorySelector(categories: categories),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _FieldLabel(text: 'Details'),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: <Widget>[
                        const DatePickerTile(),
                        const Divider(height: 1, indent: 64),
                        NoteInputField(initialValue: initialNote),
                      ],
                    ),
                  ),
                  const _AccountSection(),
                  const SizedBox(height: AppSpacing.lg),
                  const RepeatSection(),
                  const SizedBox(height: AppSpacing.lg),
                  const ReceiptSection(),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            // Pinned save bar — always visible, sits just above the keyboard.
            const _SaveBar(),
          ],
        ),
      ),
    );
  }

  void _onStatusChanged(BuildContext context, AddTransactionState state) {
    switch (state.status) {
      case AddTransactionStatus.success:
        Navigator.of(context).pop(true);
      case AddTransactionStatus.failure:
        AppSnackbar.show(
          context,
          state.errorMessage ?? 'Could not save',
          type: SnackType.error,
        );
      case AddTransactionStatus.editing:
      case AddTransactionStatus.submitting:
        break;
    }
  }
}

/// When the transaction currency differs from the home currency, shows the
/// live-converted amount with a one-tap "Use" action to switch to it.
class _ConversionHint extends StatelessWidget {
  const _ConversionHint();

  @override
  Widget build(BuildContext context) {
    final String home = context
        .read<SettingsCubit>()
        .state
        .settings
        .defaultCurrencyCode;
    return BlocBuilder<AddTransactionCubit, AddTransactionState>(
      buildWhen: (AddTransactionState p, AddTransactionState c) =>
          p.amount != c.amount || p.currencyCode != c.currencyCode,
      builder: (BuildContext context, AddTransactionState state) {
        if (state.currencyCode == home || state.amount <= 0) {
          return const SizedBox.shrink();
        }
        final double converted = CurrencyConverter.convert(
          amount: state.amount,
          from: state.currencyCode,
          to: home,
        );
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final TextTheme textTheme = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.bold),
                  size: 15,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: textTheme.bodyMedium,
                      children: <InlineSpan>[
                        TextSpan(
                          text: '≈ ',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        TextSpan(
                          text: MoneyFormatter.format(converted, home),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' in $home',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context
                      .read<AddTransactionCubit>()
                      .applyConversion(home, converted),
                  child: const Text('Use'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A pinned bottom bar holding the save button so it's always reachable
/// (no scrolling) and stays just above the keyboard.
class _SaveBar extends StatelessWidget {
  const _SaveBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: SaveTransactionButton(),
        ),
      ),
    );
  }
}

/// Optional account picker — only shows once the user has set up accounts.
/// Renders a row of choice chips ("None" + each account) above the repeat
/// section so a transaction can be attributed to a wallet.
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionCubit, AddTransactionState>(
      buildWhen: (AddTransactionState p, AddTransactionState c) =>
          p.accounts != c.accounts || p.accountId != c.accountId,
      builder: (BuildContext context, AddTransactionState state) {
        if (state.accounts.isEmpty) return const SizedBox.shrink();
        final AddTransactionCubit cubit = context.read<AddTransactionCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: AppSpacing.lg),
            const _FieldLabel(text: 'Account'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('None'),
                  selected: state.accountId == null,
                  onSelected: (_) => cubit.accountSelected(null),
                ),
                for (final Account a in state.accounts)
                  ChoiceChip(
                    label: Text(a.name),
                    selected: state.accountId == a.id,
                    onSelected: (_) => cubit.accountSelected(a.id),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
