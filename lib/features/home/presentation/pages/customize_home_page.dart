import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/features/home/domain/home_section.dart';
import 'package:jeb/features/home/presentation/cubit/home_layout_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Lets the user reorder and show/hide the home dashboard sections.
class CustomizeHomePage extends StatelessWidget {
  const CustomizeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeLayoutCubit cubit = context.read<HomeLayoutCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize home'),
        actions: <Widget>[
          TextButton(
            onPressed: cubit.resetToDefault,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: BlocBuilder<HomeLayoutCubit, HomeLayout>(
        builder: (BuildContext context, HomeLayout layout) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Drag to reorder, switch off to hide. Your home shows these '
                  'sections top to bottom.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  buildDefaultDragHandles: false,
                  itemCount: layout.order.length,
                  onReorder: cubit.reorder,
                  itemBuilder: (BuildContext context, int index) {
                    final HomeSection section = layout.order[index];
                    return _SectionTile(
                      key: ValueKey<HomeSection>(section),
                      index: index,
                      section: section,
                      enabled: layout.isEnabled(section),
                      onToggle: () => cubit.toggle(section),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.index,
    required this.section,
    required this.enabled,
    required this.onToggle,
    super.key,
  });

  final int index;
  final HomeSection section;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(
            PhosphorIcons.dotsSixVertical(PhosphorIconsStyle.bold),
            color: scheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          section.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(section.description),
        trailing: Switch(value: enabled, onChanged: (_) => onToggle()),
      ),
    );
  }
}
