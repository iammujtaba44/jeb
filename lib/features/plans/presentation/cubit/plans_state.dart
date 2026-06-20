part of 'plans_cubit.dart';

final class PlansState extends Equatable {
  const PlansState({
    this.isLoading = true,
    this.plans = const <Plan>[],
    this.paid = const <String, double>{},
    this.currency = '',
    this.totalAssets = 0,
    this.totalLiabilities = 0,
    this.hasNetWorth = false,
  });

  final bool isLoading;
  final List<Plan> plans;

  /// Total paid per plan id.
  final Map<String, double> paid;

  /// Home currency, and net-worth aggregates (converted to it).
  final String currency;
  final double totalAssets;
  final double totalLiabilities;
  final bool hasNetWorth;

  double get netWorth => totalAssets - totalLiabilities;

  double paidFor(String planId) => paid[planId] ?? 0;

  @override
  List<Object?> get props => <Object?>[
        isLoading,
        plans,
        paid,
        currency,
        totalAssets,
        totalLiabilities,
        hasNetWorth,
      ];
}
