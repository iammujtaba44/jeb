/// Database schema constants — single source of truth for table/column names.
abstract final class DbConstants {
  const DbConstants._();

  static const String databaseName = 'jeb.db';
  static const int databaseVersion = 2;

  // Tables
  static const String transactionsTable = 'transactions';
  static const String categoriesTable = 'categories';
  static const String budgetsTable = 'budgets';

  // Budget columns (id reused; overall budget keyed by [overallBudgetKey])
  static const String columnLimitAmount = 'limit_amount';
  static const String overallBudgetKey = '__overall__';

  // Shared columns
  static const String columnId = 'id';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnIsDeleted = 'is_deleted';

  // Transaction columns
  static const String columnAmount = 'amount';
  static const String columnCurrencyCode = 'currency_code';
  static const String columnCategoryId = 'category_id';
  static const String columnNote = 'note';
  static const String columnDate = 'date';
  static const String columnType = 'type';

  // Category columns
  static const String columnName = 'name';
  static const String columnIconCodePoint = 'icon_code_point';
  static const String columnColorValue = 'color_value';
}
