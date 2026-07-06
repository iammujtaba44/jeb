import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';
import 'package:jeb/features/budgets/domain/usecases/get_budgets.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/usecases/get_settings.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/get_transactions_for_month.dart';

/// Pushes the current month's spending summary to the platform home-screen
/// widgets (WidgetKit on iOS, AppWidget on Android).
///
/// The widget always shows the *current* month regardless of which month is
/// being browsed in the app, so this recomputes from the database rather than
/// reusing screen state. Everything is pre-formatted here so the native
/// widgets only render strings — no money logic on the platform side.
class HomeWidgetService {
  HomeWidgetService({
    required GetTransactionsForMonth getTransactionsForMonth,
    required GetBudgets getBudgets,
    required GetSettings getSettings,
  })  : _getTransactionsForMonth = getTransactionsForMonth,
        _getBudgets = getBudgets,
        _getSettings = getSettings;

  final GetTransactionsForMonth _getTransactionsForMonth;
  final GetBudgets _getBudgets;
  final GetSettings _getSettings;

  /// Shared container both the app and the WidgetKit extension can read.
  /// Must match the App Group enabled on the Runner and JebWidget targets.
  static const String appGroupId = 'group.com.woltrap.jebapp';

  /// The `kind` of the iOS widget and the Android receiver class name.
  static const String iosWidgetKind = 'JebWidget';
  static const String androidProviderName = 'JebWidgetProvider';

  static bool get _supported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// The "safe to spend" line: what's left of the budget spread over the
  /// remaining days of the month, e.g. "Rs1,850/day · 12 days left".
  /// Empty when there's no budget or it's already spent (the over-budget
  /// styling covers that case).
  @visibleForTesting
  static String dailyAllowanceText({
    required double spent,
    required double? limit,
    required DateTime now,
    required String currency,
  }) {
    if (limit == null || limit <= 0) return '';
    final double remaining = limit - spent;
    if (remaining <= 0) return '';
    final int lastDay = DateTime(now.year, now.month + 1, 0).day;
    final int daysLeft = lastDay - now.day + 1;
    final double perDay = remaining / daysLeft;
    final String days = daysLeft == 1 ? 'last day' : '$daysLeft days left';
    return '${MoneyFormatter.compact(perDay, currency)}/day · $days';
  }

  bool _appGroupSet = false;

  /// Recomputes this month's totals and hands them to the home-screen widget.
  /// Best-effort: failures (no widget installed, missing app group, tests)
  /// must never affect the app itself.
  Future<void> push() async {
    if (!_supported) return;
    try {
      if (Platform.isIOS && !_appGroupSet) {
        await HomeWidget.setAppGroupId(appGroupId);
        _appGroupSet = true;
      }

      final DateTime now = DateTime.now();
      final DateTime month = DateTime(now.year, now.month);

      final String currency = (await _getSettings(const NoParams())).fold(
        (_) => AppSettings.defaults.defaultCurrencyCode,
        (AppSettings s) => s.defaultCurrencyCode,
      );

      double spent = 0;
      double income = 0;
      (await _getTransactionsForMonth(month)).fold(
        (_) {},
        (List<Transaction> transactions) {
          for (final Transaction t in transactions) {
            final double converted = CurrencyConverter.convert(
              amount: t.amount,
              from: t.currencyCode,
              to: currency,
            );
            if (t.type == TransactionType.expense) {
              spent += converted;
            } else {
              income += converted;
            }
          }
        },
      );

      double? budget;
      (await _getBudgets(const NoParams())).fold(
        (_) {},
        (List<Budget> budgets) {
          for (final Budget b in budgets) {
            if (b.isOverall) budget = b.limitAmount;
          }
        },
      );

      final double? limit = budget;
      final bool hasBudget = limit != null && limit > 0;
      final int progress =
          hasBudget ? ((spent / limit) * 100).round().clamp(0, 100) : 0;

      await HomeWidget.saveWidgetData<String>(
        'month_label',
        DateFormatter.monthYear(month),
      );
      await HomeWidget.saveWidgetData<String>(
        'spent_text',
        MoneyFormatter.compact(spent, currency),
      );
      await HomeWidget.saveWidgetData<String>(
        'income_text',
        MoneyFormatter.compact(income, currency),
      );
      await HomeWidget.saveWidgetData<String>(
        'budget_text',
        hasBudget ? MoneyFormatter.compact(limit, currency) : '',
      );
      await HomeWidget.saveWidgetData<int>('progress', progress);
      await HomeWidget.saveWidgetData<bool>(
        'over_budget',
        hasBudget && spent > limit,
      );
      await HomeWidget.saveWidgetData<String>(
        'daily_text',
        dailyAllowanceText(
          spent: spent,
          limit: limit,
          now: now,
          currency: currency,
        ),
      );

      await HomeWidget.updateWidget(
        iOSName: iosWidgetKind,
        androidName: androidProviderName,
      );
    } catch (_) {
      // Widgets are an optional surface; never let them break the app.
    }
  }
}
