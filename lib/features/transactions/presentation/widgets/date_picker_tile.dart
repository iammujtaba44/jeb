import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/core/widgets/icon_badge.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';

/// Tile that opens a date picker for the transaction date.
class DatePickerTile extends StatelessWidget {
  const DatePickerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime date = context.select<AddTransactionCubit, DateTime>(
      (AddTransactionCubit cubit) => cubit.state.date,
    );

    return ListTile(
      onTap: () => _pickDate(context, date),
      leading: const IconBadge(icon: Icons.calendar_today_outlined),
      title: const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(DateFormatter.dayMonth(date)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final AddTransactionCubit cubit = context.read<AddTransactionCubit>();
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      cubit.dateChanged(picked);
    }
  }
}
