import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';
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
          if (crossCurrency && _value > 0)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.sm,
              ),
              child: Text(
                '≈ ${MoneyFormatter.compact(converted, _to.currencyCode)} '
                'into ${_to.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          const _Label('Move'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                _AccountPickerTile(
                  label: 'From',
                  selected: _from,
                  accounts: widget.accounts,
                  onChanged: _setFrom,
                ),
                const Divider(height: 1, indent: AppSpacing.md),
                _AccountPickerTile(
                  label: 'To',
                  selected: _to,
                  accounts: widget.accounts
                      .where((Account a) => a.id != _from.id)
                      .toList(),
                  onChanged: (Account a) => setState(() => _to = a),
                ),
              ],
            ),
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

class _AccountPickerTile extends StatelessWidget {
  const _AccountPickerTile({
    required this.label,
    required this.selected,
    required this.accounts,
    required this.onChanged,
  });

  final String label;
  final Account selected;
  final List<Account> accounts;
  final ValueChanged<Account> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<String>(
        value: selected.id,
        underline: const SizedBox.shrink(),
        items: <DropdownMenuItem<String>>[
          for (final Account a in accounts)
            DropdownMenuItem<String>(
              value: a.id,
              child: Text('${a.name} · ${a.currencyCode}'),
            ),
        ],
        onChanged: (String? id) {
          if (id == null) return;
          onChanged(accounts.firstWhere((Account a) => a.id == id));
        },
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
