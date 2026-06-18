part of 'transactions_cubit.dart';

sealed class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => const [];
}

final class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

final class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

final class TransactionsError extends TransactionsState {
  const TransactionsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class TransactionsLoaded extends TransactionsState {
  const TransactionsLoaded({
    required this.transactions,
    required this.categories,
    required this.month,
    required this.homeCurrency,
    this.overallBudget,
    this.categoryBudgets = const <String, double>{},
    this.isSyncing = false,
  });

  final List<Transaction> transactions;
  final List<Category> categories;
  final DateTime month;

  /// The currency all monthly totals are converted to and displayed in.
  final String homeCurrency;

  /// Optional overall monthly limit and per-category limits (home currency).
  final double? overallBudget;
  final Map<String, double> categoryBudgets;
  final bool isSyncing;

  Map<String, Category> get categoriesById =>
      <String, Category>{for (final Category c in categories) c.id: c};

  double get totalExpense => _sumOf(TransactionType.expense);
  double get totalIncome => _sumOf(TransactionType.income);
  double get balance => totalIncome - totalExpense;

  String get currencyCode => homeCurrency;

  double _sumOf(TransactionType type) => transactions
      .where((Transaction t) => t.type == type)
      .fold(
        0,
        (double sum, Transaction t) =>
            sum +
            CurrencyConverter.convert(
              amount: t.amount,
              from: t.currencyCode,
              to: homeCurrency,
            ),
      );

  TransactionsLoaded copyWith({
    List<Transaction>? transactions,
    List<Category>? categories,
    DateTime? month,
    String? homeCurrency,
    double? overallBudget,
    Map<String, double>? categoryBudgets,
    bool? isSyncing,
  }) {
    return TransactionsLoaded(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      month: month ?? this.month,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      overallBudget: overallBudget ?? this.overallBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        categories,
        month,
        homeCurrency,
        overallBudget,
        categoryBudgets,
        isSyncing,
      ];
}
