import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/domain/entities/plan_kind.dart';
import 'package:jeb/features/plans/domain/entities/plan_payment.dart';
import 'package:jeb/features/plans/domain/usecases/plans_usecases.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/usecases/get_settings.dart';

part 'plans_state.dart';

/// Drives the Plans screen: lists commitments with how much has been paid
/// toward each, and manages plans + their payments.
class PlansCubit extends Cubit<PlansState> {
  PlansCubit({
    required GetPlans getPlans,
    required SavePlan savePlan,
    required DeletePlan deletePlan,
    required PaidByPlan paidByPlan,
    required GetPlanPayments getPlanPayments,
    required AddPlanPayment addPlanPayment,
    required DeletePlanPayment deletePlanPayment,
    required GetSettings getSettings,
  })  : _getPlans = getPlans,
        _savePlan = savePlan,
        _deletePlan = deletePlan,
        _paidByPlan = paidByPlan,
        _getPlanPayments = getPlanPayments,
        _addPlanPayment = addPlanPayment,
        _deletePlanPayment = deletePlanPayment,
        _getSettings = getSettings,
        super(const PlansState());

  final GetPlans _getPlans;
  final SavePlan _savePlan;
  final DeletePlan _deletePlan;
  final PaidByPlan _paidByPlan;
  final GetPlanPayments _getPlanPayments;
  final AddPlanPayment _addPlanPayment;
  final DeletePlanPayment _deletePlanPayment;
  final GetSettings _getSettings;

  Future<void> load() async {
    final settingsResult = await _getSettings(const NoParams());
    final plansResult = await _getPlans(const NoParams());
    final paidResult = await _paidByPlan(const NoParams());
    if (isClosed) return;

    final String currency = settingsResult.fold(
      (_) => AppSettings.defaults.defaultCurrencyCode,
      (AppSettings s) => s.defaultCurrencyCode,
    );
    final List<Plan> plans =
        plansResult.fold((_) => const <Plan>[], (List<Plan> p) => p);
    final Map<String, double> paid = paidResult.fold(
      (_) => const <String, double>{},
      (Map<String, double> m) => m,
    );

    // Net worth = assets paid − loans remaining, in the home currency.
    double assets = 0;
    double liabilities = 0;
    bool hasNetWorth = false;
    for (final Plan p in plans) {
      final double paidAmount = paid[p.id] ?? 0;
      double toHome(double v) => CurrencyConverter.convert(
            amount: v,
            from: p.currencyCode,
            to: currency,
          );
      if (p.kind == PlanKind.asset) {
        assets += toHome(paidAmount);
        hasNetWorth = true;
      } else if (p.kind == PlanKind.loan) {
        liabilities += toHome(p.remaining(paidAmount));
        hasNetWorth = true;
      }
    }

    emit(
      PlansState(
        isLoading: false,
        plans: plans,
        paid: paid,
        currency: currency,
        totalAssets: assets,
        totalLiabilities: liabilities,
        hasNetWorth: hasNetWorth,
      ),
    );
  }

  Future<void> savePlan(Plan plan) async {
    await _savePlan(plan);
    await load();
  }

  Future<void> deletePlan(String id) async {
    await _deletePlan(id);
    await load();
  }

  Future<List<PlanPayment>> loadPayments(String planId) async {
    final result = await _getPlanPayments(planId);
    return result.fold((_) => const <PlanPayment>[], (List<PlanPayment> p) => p);
  }

  Future<void> addPayment(PlanPayment payment) async {
    await _addPlanPayment(payment);
    await load();
  }

  Future<void> deletePayment(String id) async {
    await _deletePlanPayment(id);
    await load();
  }
}
