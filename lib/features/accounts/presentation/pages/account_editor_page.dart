import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/widgets/currency_picker_sheet.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/account_type.dart';
import 'package:uuid/uuid.dart';

/// Create or edit an [Account]; pops the resulting account on save.
class AccountEditorPage extends StatefulWidget {
  const AccountEditorPage({
    required this.defaultCurrency,
    this.existing,
    super.key,
  });

  final String defaultCurrency;
  final Account? existing;

  @override
  State<AccountEditorPage> createState() => _AccountEditorPageState();
}

class _AccountEditorPageState extends State<AccountEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _opening;
  late final TextEditingController _note;
  late AccountType _type;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final Account? e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _opening = TextEditingController(text: _num(e?.openingBalance));
    _note = TextEditingController(text: e?.note ?? '');
    _type = e?.type ?? AccountType.cash;
    _currency = e?.currencyCode ?? widget.defaultCurrency;
  }

  static String _num(double? v) {
    if (v == null || v == 0) return '';
    return v % 1 == 0 ? v.toInt().toString() : '$v';
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  Future<void> _pickCurrency() async {
    final String? picked =
        await showCurrencyPicker(context, selected: _currency);
    if (picked != null) setState(() => _currency = picked);
  }

  void _save() {
    if (!_canSave) return;
    HapticFeedback.selectionClick();
    final Account account = Account(
      id: widget.existing?.id ?? getIt<Uuid>().v4(),
      name: _name.text.trim(),
      type: _type,
      currencyCode: _currency,
      openingBalance: double.tryParse(_opening.text.trim()) ?? 0,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      archived: widget.existing?.archived ?? false,
    );
    Navigator.of(context).pop(account);
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.existing != null;
    final String symbol = Currencies.byCode(_currency).symbol;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit account' : 'New account')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _name,
                autofocus: !editing,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  hintText: 'Account name (e.g. Meezan Bank)',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Label('Type'),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AccountType>(
              showSelectedIcon: false,
              segments: <ButtonSegment<AccountType>>[
                for (final AccountType t in AccountType.values)
                  ButtonSegment<AccountType>(value: t, label: Text(t.label)),
              ],
              selected: <AccountType>{_type},
              onSelectionChanged: (Set<AccountType> s) =>
                  setState(() => _type = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Label('Balance'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      const SizedBox(
                        width: 130,
                        child: Text('Opening balance'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        symbol,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _opening,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                          ],
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            filled: false,
                            border: InputBorder.none,
                            hintText: '0',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: AppSpacing.md),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Currency'),
                  trailing: TextButton(
                    onPressed: _pickCurrency,
                    child: Text(_currency),
                  ),
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
            child: Text(editing ? 'Save changes' : 'Create account'),
          ),
          const SizedBox(height: AppSpacing.md),
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
