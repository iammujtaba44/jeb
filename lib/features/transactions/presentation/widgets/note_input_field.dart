import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/widgets/icon_badge.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';

/// Tile-style note row (borderless field) designed to sit inside a card.
class NoteInputField extends StatefulWidget {
  const NoteInputField({this.initialValue, super.key});

  final String? initialValue;

  @override
  State<NoteInputField> createState() => _NoteInputFieldState();
}

class _NoteInputFieldState extends State<NoteInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const IconBadge(icon: Icons.notes_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                hintText: 'Add a note (optional)',
              ),
              onChanged: context.read<AddTransactionCubit>().noteChanged,
            ),
          ),
        ],
      ),
    );
  }
}
