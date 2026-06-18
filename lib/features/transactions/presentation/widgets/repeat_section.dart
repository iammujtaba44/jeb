import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The "Repeat" controls in the add/edit form:
/// - editing a recurring occurrence → a banner with "Stop recurring"
/// - editing a one-off → nothing (a one-off stays a one-off)
/// - creating a new transaction → a toggle that reveals frequency + end date
class RepeatSection extends StatelessWidget {
  const RepeatSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionCubit, AddTransactionState>(
      buildWhen: (AddTransactionState p, AddTransactionState c) =>
          p.repeat != c.repeat ||
          p.frequency != c.frequency ||
          p.endDate != c.endDate ||
          p.date != c.date,
      builder: (BuildContext context, AddTransactionState state) {
        if (state.isRecurringOccurrence) return const _RecurringBanner();
        if (state.isEditing) return const SizedBox.shrink();
        return _RepeatEditor(state: state);
      },
    );
  }
}

class _RepeatEditor extends StatelessWidget {
  const _RepeatEditor({required this.state});

  final AddTransactionState state;

  @override
  Widget build(BuildContext context) {
    final AddTransactionCubit cubit = context.read<AddTransactionCubit>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          SwitchListTile(
            value: state.repeat,
            onChanged: cubit.repeatChanged,
            secondary: Icon(
              PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
            ),
            title: const Text(
              'Repeat',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              state.repeat
                  ? 'Repeats from ${DateFormatter.dayMonth(state.date)}'
                  : 'Make this a recurring transaction',
            ),
          ),
          if (state.repeat) ...<Widget>[
            const Divider(height: 1, indent: 56),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<RecurrenceFrequency>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<RecurrenceFrequency>>[
                    for (final RecurrenceFrequency f
                        in RecurrenceFrequency.values)
                      ButtonSegment<RecurrenceFrequency>(
                        value: f,
                        label: Text(f.label),
                      ),
                  ],
                  selected: <RecurrenceFrequency>{state.frequency},
                  onSelectionChanged: (Set<RecurrenceFrequency> s) =>
                      cubit.frequencyChanged(s.first),
                ),
              ),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: const Text('Ends'),
              subtitle: Text(
                state.endDate == null
                    ? 'Never'
                    : DateFormatter.fullDate(state.endDate!),
              ),
              trailing: state.endDate == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear end date',
                      onPressed: () => cubit.endDateChanged(null),
                    ),
              onTap: () => _pickEnd(context, cubit, state),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickEnd(
    BuildContext context,
    AddTransactionCubit cubit,
    AddTransactionState state,
  ) async {
    final DateTime start = state.date;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.endDate ?? start,
      firstDate: start,
      lastDate: DateTime(2100),
    );
    if (picked != null) cubit.endDateChanged(picked);
  }
}

class _RecurringBanner extends StatelessWidget {
  const _RecurringBanner();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(
              PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
              size: 22,
              color: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                'Part of a recurring series. Edits here change only this one.',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () => _confirmStop(context),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStop(BuildContext context) async {
    final AddTransactionCubit cubit = context.read<AddTransactionCubit>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Stop recurring?'),
        content: const Text(
          'No new transactions will be generated. Transactions already created '
          'are kept.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop recurring'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.stopRecurring();
  }
}
