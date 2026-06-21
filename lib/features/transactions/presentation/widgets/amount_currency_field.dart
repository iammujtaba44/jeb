import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/widgets/currency_picker_sheet.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';

/// Modern amount entry: a large hero field with the currency symbol and a
/// tappable currency chip that opens a picker. Controller-based so typing is
/// always reliable.
class AmountCurrencyField extends StatefulWidget {
  const AmountCurrencyField({this.initialAmount, super.key});

  final double? initialAmount;

  @override
  State<AmountCurrencyField> createState() => _AmountCurrencyFieldState();
}

class _AmountCurrencyFieldState extends State<AmountCurrencyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final double amount = widget.initialAmount ?? 0;
    _controller = TextEditingController(
      text: amount <= 0
          ? ''
          : (amount % 1 == 0 ? amount.toInt().toString() : '$amount'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _format(double v) => v % 1 == 0
      ? v.toInt().toString()
      : double.parse(v.toStringAsFixed(2)).toString();

  /// Reflects an amount changed elsewhere (e.g. the "Use €X" conversion) in the
  /// field, without disturbing the user's own typing.
  void _syncFromState(double amount) {
    final double current = double.tryParse(_controller.text) ?? 0;
    if ((current - amount).abs() < 0.001) return;
    final String text = amount <= 0 ? '' : _format(amount);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Currency currency = Currencies.byCode(
      context.select<AddTransactionCubit, String>(
        (AddTransactionCubit cubit) => cubit.state.currencyCode,
      ),
    );

    return BlocListener<AddTransactionCubit, AddTransactionState>(
      listenWhen: (AddTransactionState p, AddTransactionState c) =>
          p.amount != c.amount,
      listener: (BuildContext context, AddTransactionState state) =>
          _syncFromState(state.amount),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'AMOUNT',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                _CurrencyChip(code: currency.code),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  currency.symbol,
                  style: textTheme.headlineMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: widget.initialAmount == null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                    onChanged: (String value) => context
                        .read<AddTransactionCubit>()
                        .amountChanged(double.tryParse(value) ?? 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.public, size: 18),
      label: Text(code),
      onPressed: () => _pickCurrency(context),
    );
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final AddTransactionCubit cubit = context.read<AddTransactionCubit>();
    final String? picked = await showCurrencyPicker(
      context,
      selected: cubit.state.currencyCode,
    );
    if (picked != null) cubit.currencyChanged(picked);
  }
}
