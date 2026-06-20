import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/presentation/cubit/plans_cubit.dart';
import 'package:jeb/features/plans/presentation/pages/plan_detail_page.dart';
import 'package:jeb/features/plans/presentation/pages/plans_page.dart';
import 'package:jeb/features/plans/presentation/widgets/plan_kind_visuals.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A horizontal, swipeable strip of plan progress for the home dashboard.
/// Requires a [PlansCubit] ancestor; renders nothing until there are plans.
class PlansCarousel extends StatelessWidget {
  const PlansCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlansCubit, PlansState>(
      builder: (BuildContext context, PlansState state) {
        if (state.isLoading || state.plans.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Header(
              onSeeAll: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const PlansPage()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: state.plans.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (BuildContext context, int index) {
                  final Plan plan = state.plans[index];
                  return _PlanChip(
                    plan: plan,
                    paid: state.paidFor(plan.id),
                    onTap: () => _openDetail(context, plan),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  void _openDetail(BuildContext context, Plan plan) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<PlansCubit>.value(
          value: context.read<PlansCubit>(),
          child: PlanDetailPage(planId: plan.id),
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.plan, required this.paid, required this.onTap});

  final Plan plan;
  final double paid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = PlanKindVisuals.color(plan.kind);
    final double? progress = plan.progress(paid);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 184,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(PlanKindVisuals.icon(plan.kind), color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (progress != null)
                  Text(
                    '${(progress * 100).round()}%',
                    style: textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${plan.kind.contributeVerb} '
                  '${MoneyFormatter.compact(paid, plan.currencyCode)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: LinearProgressIndicator(
                    value: progress ?? 0,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.18),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.sm, 0),
      child: Row(
        children: <Widget>[
          Icon(PhosphorIcons.target(PhosphorIconsStyle.fill),
              size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            'Plans',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}
