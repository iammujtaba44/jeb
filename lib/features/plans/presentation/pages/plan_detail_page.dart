import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/services/receipt_store.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/domain/entities/plan_payment.dart';
import 'package:jeb/features/plans/presentation/cubit/plans_cubit.dart';
import 'package:jeb/features/plans/presentation/pages/plan_editor_page.dart';
import 'package:jeb/features/plans/presentation/widgets/plan_kind_visuals.dart';
import 'package:jeb/features/transactions/presentation/pages/receipt_viewer_page.dart';
import 'package:uuid/uuid.dart';

class PlanDetailPage extends StatefulWidget {
  const PlanDetailPage({required this.planId, super.key});

  final String planId;

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  late Future<List<PlanPayment>> _payments;
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _inited = true;
      _payments = context.read<PlansCubit>().loadPayments(widget.planId);
    }
  }

  void _reloadPayments() => setState(
        () => _payments = context.read<PlansCubit>().loadPayments(widget.planId),
      );

  Future<void> _addPayment(Plan plan) async {
    final PlansCubit cubit = context.read<PlansCubit>();
    final _PaymentDraft? draft = await _showAddPaymentSheet(context, plan);
    if (draft == null) return;
    HapticFeedback.selectionClick();
    await cubit.addPayment(
      PlanPayment(
        id: getIt<Uuid>().v4(),
        planId: plan.id,
        amount: draft.amount,
        date: draft.date,
        note: draft.note,
        receiptPaths: draft.receiptPaths,
      ),
    );
    if (mounted) _reloadPayments();
  }

  Future<void> _editPlan(Plan plan) async {
    final Plan? updated = await Navigator.of(context).push<Plan>(
      MaterialPageRoute<Plan>(
        builder: (_) => PlanEditorPage(
          defaultCurrency: plan.currencyCode,
          existing: plan,
        ),
      ),
    );
    if (updated != null && mounted) {
      await context.read<PlansCubit>().savePlan(updated);
    }
  }

  Future<void> _deletePlan(Plan plan) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${plan.name}"?'),
        content: const Text('The plan and its payments will be removed.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if ((ok ?? false) && mounted) {
      final NavigatorState nav = Navigator.of(context);
      await context.read<PlansCubit>().deletePlan(plan.id);
      if (nav.canPop()) nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlansCubit, PlansState>(
      builder: (BuildContext context, PlansState state) {
        final Plan? plan = state.plans
            .where((Plan p) => p.id == widget.planId)
            .firstOrNull;
        if (plan == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final double paid = state.paidFor(plan.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(plan.name, overflow: TextOverflow.ellipsis),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => _editPlan(plan),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _deletePlan(plan),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addPayment(plan),
            icon: const Icon(Icons.add),
            label: const Text('Payment'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              _Header(plan: plan, paid: paid),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  'PAYMENTS',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<List<PlanPayment>>(
                future: _payments,
                builder: (BuildContext context,
                    AsyncSnapshot<List<PlanPayment>> snap) {
                  final List<PlanPayment> payments =
                      snap.data ?? const <PlanPayment>[];
                  if (payments.isEmpty) {
                    return Card(
                      child: ListTile(
                        title: const Text('No payments yet'),
                        subtitle:
                            const Text('Tap "Payment" to log your first one.'),
                      ),
                    );
                  }
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < payments.length; i++) ...<Widget>[
                          if (i > 0) const Divider(height: 1),
                          _PaymentTile(
                            payment: payments[i],
                            currency: plan.currencyCode,
                            onDelete: () async {
                              final PlansCubit cubit =
                                  context.read<PlansCubit>();
                              await cubit.deletePayment(payments[i].id);
                              if (mounted) _reloadPayments();
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 88),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.plan, required this.paid});

  final Plan plan;
  final double paid;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color color = PlanKindVisuals.color(plan.kind);
    final double? progress = plan.progress(paid);
    final int? monthsLeft = plan.monthsLeft(paid);
    final String cur = plan.currencyCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(PlanKindVisuals.icon(plan.kind), color: color),
                const SizedBox(width: AppSpacing.sm),
                Text(plan.kind.label, style: textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              MoneyFormatter.compact(paid, cur),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              plan.hasTarget
                  ? '${plan.kind.contributeVerb.toLowerCase()} of '
                      '${MoneyFormatter.compact(plan.targetAmount!, cur)}'
                  : '${plan.kind.contributeVerb.toLowerCase()} so far',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (progress != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: progress,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '${MoneyFormatter.compact(plan.remaining(paid), cur)} left',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (monthsLeft != null && monthsLeft > 0)
                    Text(
                      '~$monthsLeft mo left',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.payment,
    required this.currency,
    required this.onDelete,
  });

  final PlanPayment payment;
  final String currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          title: Text(
            MoneyFormatter.format(payment.amount, currency),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            payment.note?.isNotEmpty ?? false
                ? '${DateFormatter.dayMonth(payment.date)} · ${payment.note}'
                : DateFormatter.dayMonth(payment.date),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete payment',
            onPressed: onDelete,
          ),
        ),
        if (payment.hasReceipts)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                for (final String path in payment.receiptPaths) ...<Widget>[
                  _ReceiptThumb(relativePath: path),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ReceiptThumb extends StatelessWidget {
  const _ReceiptThumb({required this.relativePath});

  final String relativePath;

  @override
  Widget build(BuildContext context) {
    final String absolute = getIt<ReceiptStore>().absolutePath(relativePath);
    return GestureDetector(
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptViewerPage(absolutePath: absolute),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Image.file(
          File(absolute),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 52,
            height: 52,
            color: const Color(0x11000000),
            child: const Icon(Icons.broken_image_outlined, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ReceiptDraftThumb extends StatelessWidget {
  const _ReceiptDraftThumb({
    required this.relativePath,
    required this.onRemove,
  });

  final String relativePath;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final String absolute = getIt<ReceiptStore>().absolutePath(relativePath);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Image.file(
            File(absolute),
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 52,
              height: 52,
              color: const Color(0x11000000),
              child: const Icon(Icons.broken_image_outlined, size: 20),
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: CircleAvatar(
              radius: 10,
              backgroundColor: Theme.of(context).colorScheme.error,
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

class _PaymentDraft {
  const _PaymentDraft({
    required this.amount,
    required this.date,
    this.note,
    this.receiptPaths = const <String>[],
  });
  final double amount;
  final DateTime date;
  final String? note;
  final List<String> receiptPaths;
}

Future<_PaymentDraft?> _showAddPaymentSheet(BuildContext context, Plan plan) {
  return showModalBottomSheet<_PaymentDraft>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _AddPaymentSheet(plan: plan),
    ),
  );
}

class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet({required this.plan});

  final Plan plan;

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final List<String> _receipts = <String>[];
  DateTime _date = DateTime.now();

  static const int _maxReceipts = 2;

  @override
  void initState() {
    super.initState();
    final double? installment = widget.plan.installmentAmount;
    if (installment != null) {
      _amount.text =
          installment % 1 == 0 ? installment.toInt().toString() : '$installment';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
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

  Future<void> _attachReceipt() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 80,
    );
    if (picked == null) return;
    final String relative = await getIt<ReceiptStore>().save(picked.path);
    if (mounted) setState(() => _receipts.add(relative));
  }

  void _save() {
    final double amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) return;
    Navigator.of(context).pop(
      _PaymentDraft(
        amount: amount,
        date: DateTime(_date.year, _date.month, _date.day),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        receiptPaths: List<String>.unmodifiable(_receipts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String symbol = Currencies.byCode(widget.plan.currencyCode).symbol;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Add payment',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Text(symbol,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Date'),
              subtitle: Text(DateFormatter.fullDate(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                for (final String path in _receipts) ...<Widget>[
                  _ReceiptDraftThumb(
                    relativePath: path,
                    onRemove: () => setState(() => _receipts.remove(path)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (_receipts.length < _maxReceipts)
                  OutlinedButton.icon(
                    onPressed: _attachReceipt,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(_receipts.isEmpty ? 'Add receipt' : 'Add'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
