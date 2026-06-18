import 'package:flutter/material.dart';
import 'package:jeb/core/constants/category_options.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:uuid/uuid.dart';

/// Create or edit a category. Pops the resulting [Category], or null if cancelled.
class CategoryEditorPage extends StatefulWidget {
  const CategoryEditorPage({this.existing, super.key});

  final Category? existing;

  @override
  State<CategoryEditorPage> createState() => _CategoryEditorPageState();
}

class _CategoryEditorPageState extends State<CategoryEditorPage> {
  late final TextEditingController _name;
  late TransactionType _type;
  late int _iconCodePoint;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    final Category? e = widget.existing;
    _name = TextEditingController(text: e?.name);
    _type = e?.type ?? TransactionType.expense;
    _iconCodePoint = e?.iconCodePoint ?? CategoryOptions.icons.first.codePoint;
    _colorValue = e?.colorValue ?? CategoryOptions.colors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final Category category = Category(
      id: widget.existing?.id ?? getIt<Uuid>().v4(),
      name: _name.text.trim(),
      iconCodePoint: _iconCodePoint,
      colorValue: _colorValue,
      type: _type,
    );
    Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Color(_colorValue);
    final bool canSave = _name.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New category' : 'Edit category'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                IconData(_iconCodePoint, fontFamily: 'MaterialIcons'),
                color: color,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TransactionType>(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text('Income'),
                ),
              ],
              selected: <TransactionType>{_type},
              onSelectionChanged: (Set<TransactionType> s) =>
                  setState(() => _type = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Label('Icon'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: CategoryOptions.icons
                .map(
                  (IconData icon) => _IconOption(
                    icon: icon,
                    color: color,
                    selected: icon.codePoint == _iconCodePoint,
                    onTap: () => setState(() => _iconCodePoint = icon.codePoint),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Label('Color'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: CategoryOptions.colors
                .map(
                  (int value) => _ColorOption(
                    value: value,
                    selected: value == _colorValue,
                    onTap: () => setState(() => _colorValue = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: canSave ? _save : null,
            child: const Text('Save'),
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

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: selected ? Border.all(color: color, width: 2) : null,
        ),
        child: Icon(icon, color: selected ? color : scheme.onSurfaceVariant),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(value);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}
