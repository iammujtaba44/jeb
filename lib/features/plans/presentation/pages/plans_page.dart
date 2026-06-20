import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/core/widgets/icon_badge.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/presentation/cubit/plans_cubit.dart';
import 'package:jeb/features/plans/presentation/pages/plan_detail_page.dart';
import 'package:jeb/features/plans/presentation/pages/plan_editor_page.dart';
import 'package:jeb/features/plans/presentation/widgets/plan_kind_visuals.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlansCubit>(
      create: (_) => getIt<PlansCubit>()..load(),
      child: const PlansView(),
    );
  }
}

class PlansView extends StatelessWidget {
  const PlansView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New plan',
            onPressed: () => _newPlan(context),
          ),
        ],
      ),
      body: BlocBuilder<PlansCubit, PlansState>(
        builder: (BuildContext context, PlansState state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.plans.isEmpty) return const _EmptyState();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              if (state.hasNetWorth) ...<Widget>[
                _NetWorthCard(state: state),
                const SizedBox(height: AppSpacing.lg),
              ],
              for (final Plan plan in state.plans) ...<Widget>[
                _PlanCard(plan: plan, paid: state.paidFor(plan.id)),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

Future<void> _newPlan(BuildContext context) async {
  final PlansCubit cubit = context.read<PlansCubit>();
  final String currency =
      context.read<SettingsCubit>().state.settings.defaultCurrencyCode;
  final Plan? plan = await Navigator.of(context).push<Plan>(
    MaterialPageRoute<Plan>(
      builder: (_) => PlanEditorPage(defaultCurrency: currency),
    ),
  );
  if (plan != null) await cubit.savePlan(plan);
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.state});

  final PlansState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String cur = state.currency;
    final bool positive = state.netWorth >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            Color.alphaBlend(
              scheme.tertiary.withValues(alpha: 0.45),
              scheme.primary,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Net position',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${positive ? '' : '-'}${MoneyFormatter.compact(state.netWorth.abs(), cur)}',
            style: textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _NetStat(
                  label: 'Assets',
                  value: MoneyFormatter.compact(state.totalAssets, cur),
                ),
              ),
              Expanded(
                child: _NetStat(
                  label: 'Owed',
                  value: MoneyFormatter.compact(state.totalLiabilities, cur),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetStat extends StatelessWidget {
  const _NetStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onPrimary.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.paid});

  final Plan plan;
  final double paid;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color color = PlanKindVisuals.color(plan.kind);
    final double? progress = plan.progress(paid);
    final bool done = plan.isComplete(paid);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider<PlansCubit>.value(
              value: context.read<PlansCubit>(),
              child: PlanDetailPage(planId: plan.id),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconBadge(icon: PlanKindVisuals.icon(plan.kind), color: color),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          plan.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${plan.kind.contributeVerb} '
                          '${MoneyFormatter.compact(paid, plan.currencyCode)}'
                          '${plan.hasTarget ? ' of ${MoneyFormatter.compact(plan.targetAmount!, plan.currencyCode)}' : ''}',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (done)
                    Icon(Icons.check_circle, color: color)
                  else if (progress != null)
                    Text(
                      '${(progress * 100).round()}%',
                      style: textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (progress != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: LinearProgressIndicator(
                    value: progress,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                    minHeight: 8,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              PhosphorIcons.target(PhosphorIconsStyle.duotone),
              size: 56,
              color: scheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No plans yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Track installments, loans, or zakat. Tap + to add a plan and '
              'log payments toward it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
