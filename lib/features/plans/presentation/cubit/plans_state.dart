part of 'plans_cubit.dart';

final class PlansState extends Equatable {
  const PlansState({
    this.isLoading = true,
    this.plans = const <Plan>[],
    this.paid = const <String, double>{},
  });

  final bool isLoading;
  final List<Plan> plans;

  /// Total paid per plan id.
  final Map<String, double> paid;

  double paidFor(String planId) => paid[planId] ?? 0;

  @override
  List<Object?> get props => <Object?>[isLoading, plans, paid];
}
