import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/core/widgets/icon_badge.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';
import 'package:jeb/features/accounts/presentation/widgets/account_type_visuals.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

/// Records a [Transfer] between two accounts; pops the transfer on save.
class TransferEditorPage extends StatefulWidget {
  const TransferEditorPage({required this.accounts, super.key});

  final List<Account> accounts;

  @override
  State<TransferEditorPage> createState() => _TransferEditorPageState();
}

class _TransferEditorPageState extends State<TransferEditorPage> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  late Account _from;
  late Account _to;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _from = widget.accounts.first;
    _to = widget.accounts.firstWhere(
      (Account a) => a.id != _from.id,
      orElse: () => widget.accounts.last,
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;
  bool get _canSave => _value > 0 && _from.id != _to.id;

  void _setFrom(Account a) {
    setState(() {
      _from = a;
      if (_to.id == _from.id) {
        _to = widget.accounts.firstWhere(
          (Account x) => x.id != _from.id,
          orElse: () => _from,
        );
      }
    });
  }

  void _swap() {
    HapticFeedback.selectionClick();
    setState(() {
      final Account previousFrom = _from;
      _from = _to;
      _to = previousFrom;
    });
  }

  Future<void> _pickAccount({required bool isFrom}) async {
    final List<Account> options = isFrom
        ? widget.accounts
        : widget.accounts.where((Account a) => a.id != _from.id).toList();
    final Account? picked = await showModalBottomSheet<Account>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AccountPickerSheet(
        title: isFrom ? 'Transfer from' : 'Transfer to',
        accounts: options,
        selectedId: isFrom ? _from.id : _to.id,
      ),
    );
    if (picked == null) return;
    if (isFrom) {
      _setFrom(picked);
    } else {
      setState(() => _to = picked);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_canSave) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(
      Transfer(
        id: getIt<Uuid>().v4(),
        fromAccountId: _from.id,
        toAccountId: _to.id,
        amount: _value,
        date: _date,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String symbol = Currencies.byCode(_from.currencyCode).symbol;
    final bool crossCurrency = _from.currencyCode != _to.currencyCode;
    final double converted = CurrencyConverter.convert(
      amount: _value,
      from: _from.currencyCode,
      to: _to.currencyCode,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          const _Label('Amount'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    symbol,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      style: Theme.of(context).textTheme.titleLarge,
                      decoration: const InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (crossCurrency && _value > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _ConversionHint(from: _from, to: _to, converted: converted),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _Label('Move'),
          const SizedBox(height: AppSpacing.sm),
          Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    _AccountSelectRow(
                      label: 'From',
                      account: _from,
                      onTap: () => _pickAccount(isFrom: true),
                    ),
                    const Divider(height: 1, indent: 72),
                    _AccountSelectRow(
                      label: 'To',
                      account: _to,
                      onTap: () => _pickAccount(isFrom: false),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _SwapButton(onTap: _swap),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Label('Details'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Date'),
                  subtitle: Text(DateFormatter.fullDate(_date)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
                const Divider(height: 1, indent: AppSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: TextField(
                    controller: _note,
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      hintText: 'Note (optional)',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _canSave ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Save transfer'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Shows the live converted amount the destination account will receive, plus
/// the exchange rate used.
class _ConversionHint extends StatelessWidget {
  const _ConversionHint({
    required this.from,
    required this.to,
    required this.converted,
  });

  final Account from;
  final Account to;
  final double converted;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double unitRate = CurrencyConverter.convert(
      amount: 1,
      from: from.currencyCode,
      to: to.currencyCode,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.bold),
              size: 16, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    style: textTheme.bodyMedium,
                    children: <InlineSpan>[
                      TextSpan(
                        text: '${to.name} receives ',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      TextSpan(
                        text: MoneyFormatter.format(converted, to.currencyCode),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '1 ${from.currencyCode} = ${_rate(unitRate)} ${to.currencyCode}',
                  style: textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A readable rate: more decimals for small numbers, trailing zeros trimmed.
  static String _rate(double value) {
    final int decimals = value >= 1
        ? 2
        : value >= 0.01
            ? 4
            : 6;
    return double.parse(value.toStringAsFixed(decimals)).toString();
  }
}

/// A tappable From/To row showing the chosen account; opens a picker sheet.
class _AccountSelectRow extends StatelessWidget {
  const _AccountSelectRow({
    required this.label,
    required this.account,
    required this.onTap,
  });

  final String label;
  final Account account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = AccountTypeVisuals.color(account.type);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            IconBadge(icon: AccountTypeVisuals.icon(account.type), color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Text(
              account.currencyCode,
              style: textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 6),
            Icon(PhosphorIcons.caretUpDown(),
                size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Round button straddling the From/To divider that flips the two accounts.
class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: CircleBorder(
        side: BorderSide(color: scheme.outlineVariant),
      ),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            PhosphorIcons.arrowsDownUp(PhosphorIconsStyle.bold),
            size: 18,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Modal sheet listing accounts to choose from, with the current one ticked.
class _AccountPickerSheet extends StatelessWidget {
  const _AccountPickerSheet({
    required this.title,
    required this.accounts,
    required this.selectedId,
  });

  final String title;
  final List<Account> accounts;
  final String selectedId;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (final Account a in accounts)
                  ListTile(
                    leading: IconBadge(
                      icon: AccountTypeVisuals.icon(a.type),
                      color: AccountTypeVisuals.color(a.type),
                    ),
                    title: Text(
                      a.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${a.type.label} · ${a.currencyCode}'),
                    trailing: a.id == selectedId
                        ? Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                            color: scheme.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(a),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
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
