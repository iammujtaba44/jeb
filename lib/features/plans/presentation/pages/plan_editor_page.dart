import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/core/widgets/currency_picker_sheet.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/domain/entities/plan_kind.dart';
import 'package:uuid/uuid.dart';

/// Create or edit a [Plan]; pops the resulting plan on save.
class PlanEditorPage extends StatefulWidget {
  const PlanEditorPage({
    required this.defaultCurrency,
    this.existing,
    super.key,
  });

  final String defaultCurrency;
  final Plan? existing;

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _installment;
  late final TextEditingController _note;
  late PlanKind _kind;
  late String _currency;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    final Plan? e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _target = TextEditingController(text: _num(e?.targetAmount));
    _installment = TextEditingController(text: _num(e?.installmentAmount));
    _note = TextEditingController(text: e?.note ?? '');
    _kind = e?.kind ?? PlanKind.asset;
    _currency = e?.currencyCode ?? widget.defaultCurrency;
    _startDate = e?.startDate ?? DateTime.now();
  }

  static String _num(double? v) =>
      v == null ? '' : (v % 1 == 0 ? v.toInt().toString() : '$v');

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _installment.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  Future<void> _pickCurrency() async {
    final String? picked =
        await showCurrencyPicker(context, selected: _currency);
    if (picked != null) setState(() => _currency = picked);
  }

  Future<void> _pickStart() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _save() {
    if (!_canSave) return;
    HapticFeedback.selectionClick();
    final Plan plan = Plan(
      id: widget.existing?.id ?? getIt<Uuid>().v4(),
      name: _name.text.trim(),
      kind: _kind,
      currencyCode: _currency,
      startDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
      targetAmount: double.tryParse(_target.text.trim()),
      installmentAmount: double.tryParse(_installment.text.trim()),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    Navigator.of(context).pop(plan);
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.existing != null;
    final String symbol = Currencies.byCode(_currency).symbol;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit plan' : 'New plan')),
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
                  hintText: 'Plan name (e.g. House installments)',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Label('Kind'),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PlanKind>(
              showSelectedIcon: false,
              segments: <ButtonSegment<PlanKind>>[
                for (final PlanKind k in PlanKind.values)
                  ButtonSegment<PlanKind>(value: k, label: Text(k.label)),
              ],
              selected: <PlanKind>{_kind},
              onSelectionChanged: (Set<PlanKind> s) =>
                  setState(() => _kind = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Label('Amounts'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                _AmountField(
                  controller: _target,
                  symbol: symbol,
                  label: 'Target (total)',
                  hint: 'Optional',
                ),
                const Divider(height: 1, indent: AppSpacing.md),
                _AmountField(
                  controller: _installment,
                  symbol: symbol,
                  label: 'Per month',
                  hint: 'Optional · for "months left"',
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
                  title: const Text('Start date'),
                  subtitle: Text(DateFormatter.fullDate(_startDate)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickStart,
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
            child: Text(editing ? 'Save changes' : 'Create plan'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.symbol,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String symbol;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(width: 110, child: Text(label)),
          const SizedBox(width: AppSpacing.sm),
          Text(symbol,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                hintText: hint,
              ),
            ),
          ),
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
