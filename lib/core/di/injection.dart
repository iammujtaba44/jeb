import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:jeb/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:jeb/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:jeb/features/budgets/domain/repositories/budget_repository.dart';
import 'package:jeb/features/budgets/domain/usecases/get_budgets.dart';
import 'package:jeb/features/budgets/domain/usecases/remove_budget.dart';
import 'package:jeb/features/budgets/domain/usecases/set_budget.dart';
import 'package:jeb/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:jeb/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:jeb/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:jeb/features/settings/domain/repositories/settings_repository.dart';
import 'package:jeb/features/settings/domain/usecases/get_settings.dart';
import 'package:jeb/features/settings/domain/usecases/save_settings.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:jeb/features/transactions/data/datasources/app_database.dart';
import 'package:jeb/features/transactions/data/datasources/cloud_file_store.dart';
import 'package:jeb/features/transactions/data/datasources/cloud_sync_datasource.dart';
import 'package:jeb/features/transactions/data/datasources/icloud_file_store.dart';
import 'package:jeb/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:jeb/features/transactions/data/sync/sync_engine.dart';
import 'package:jeb/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:jeb/features/transactions/domain/usecases/add_transaction.dart';
import 'package:jeb/features/transactions/domain/usecases/delete_category.dart';
import 'package:jeb/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/domain/usecases/get_transactions_for_month.dart';
import 'package:jeb/features/transactions/domain/usecases/save_category.dart';
import 'package:jeb/features/transactions/domain/usecases/search_transactions.dart';
import 'package:jeb/features/transactions/domain/usecases/sync_data.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';
import 'package:jeb/features/transactions/presentation/cubit/categories_cubit.dart';
import 'package:jeb/features/transactions/presentation/cubit/search_cubit.dart';
import 'package:jeb/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service locator. Resolved once at startup via [configureDependencies].
final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ── External ──────────────────────────────────────────────────────────
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton<Uuid>(Uuid.new);

  // ── Data: database & sources ─────────────────────────────────────────
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  getIt.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(getIt<AppDatabase>()),
  );

  // ── Data: sync (iCloud on Apple, local-file elsewhere) ──────────────
  getIt.registerLazySingleton<CloudFileStore>(_buildCloudFileStore);
  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      local: getIt<TransactionLocalDataSource>(),
      cloudFileStore: getIt<CloudFileStore>(),
    ),
  );
  getIt.registerLazySingleton<CloudSyncDataSource>(
    () => CloudSyncDataSourceImpl(getIt<SyncEngine>()),
  );

  // ── Data: repository ─────────────────────────────────────────────────
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      localDataSource: getIt<TransactionLocalDataSource>(),
      cloudSyncDataSource: getIt<CloudSyncDataSource>(),
    ),
  );

  // ── Settings feature ─────────────────────────────────────────────────
  getIt
    ..registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()),
    )
    ..registerLazySingleton<GetSettings>(
      () => GetSettings(getIt<SettingsRepository>()),
    )
    ..registerLazySingleton<SaveSettings>(
      () => SaveSettings(getIt<SettingsRepository>()),
    );

  // ── Budgets feature ──────────────────────────────────────────────────
  getIt
    ..registerLazySingleton<BudgetLocalDataSource>(
      () => BudgetLocalDataSourceImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<BudgetRepository>(
      () => BudgetRepositoryImpl(getIt<BudgetLocalDataSource>()),
    )
    ..registerLazySingleton<GetBudgets>(
      () => GetBudgets(getIt<BudgetRepository>()),
    )
    ..registerLazySingleton<SetBudget>(
      () => SetBudget(getIt<BudgetRepository>()),
    )
    ..registerLazySingleton<RemoveBudget>(
      () => RemoveBudget(getIt<BudgetRepository>()),
    );

  // ── Domain: use cases ────────────────────────────────────────────────
  getIt
    ..registerLazySingleton<GetTransactionsForMonth>(
      () => GetTransactionsForMonth(getIt<TransactionRepository>()),
    )
    ..registerLazySingleton<GetCategories>(
      () => GetCategories(getIt<TransactionRepository>()),
    )
    ..registerLazySingleton<AddTransaction>(
      () => AddTransaction(getIt<TransactionRepository>()),
    )
    ..registerLazySingleton<DeleteTransaction>(
      () => DeleteTransaction(getIt<TransactionRepository>()),
    )
    ..registerLazySingleton<SyncData>(
      () => SyncData(getIt<TransactionRepository>()),
    )
    ..registerLazySingleton<SaveCategory>(
      () => SaveCategory(getIt<TransactionRepository>()),
    )
    ..registerLazySingleton<DeleteCategory>(
      () => DeleteCategory(getIt<TransactionRepository>()),
    )
    ..registerLazySingleton<SearchTransactions>(
      () => SearchTransactions(getIt<TransactionRepository>()),
    );

  // ── Presentation: cubits (new instance per screen) ───────────────────
  getIt
    ..registerFactory<TransactionsCubit>(
      () => TransactionsCubit(
        getTransactionsForMonth: getIt<GetTransactionsForMonth>(),
        getCategories: getIt<GetCategories>(),
        deleteTransaction: getIt<DeleteTransaction>(),
        syncData: getIt<SyncData>(),
        getSettings: getIt<GetSettings>(),
        addTransaction: getIt<AddTransaction>(),
        getBudgets: getIt<GetBudgets>(),
      ),
    )
    ..registerFactory<BudgetsCubit>(
      () => BudgetsCubit(
        getBudgets: getIt<GetBudgets>(),
        setBudget: getIt<SetBudget>(),
        removeBudget: getIt<RemoveBudget>(),
        getCategories: getIt<GetCategories>(),
      ),
    )
    ..registerFactory<CategoriesCubit>(
      () => CategoriesCubit(
        getCategories: getIt<GetCategories>(),
        saveCategory: getIt<SaveCategory>(),
        deleteCategory: getIt<DeleteCategory>(),
      ),
    )
    ..registerFactory<SearchCubit>(
      () => SearchCubit(
        searchTransactions: getIt<SearchTransactions>(),
        getCategories: getIt<GetCategories>(),
      ),
    )
    ..registerFactory<AddTransactionCubit>(
      () => AddTransactionCubit(
        addTransaction: getIt<AddTransaction>(),
        uuid: getIt<Uuid>(),
      ),
    )
    ..registerLazySingleton<SettingsCubit>(
      () => SettingsCubit(
        getSettings: getIt<GetSettings>(),
        saveSettings: getIt<SaveSettings>(),
        syncData: getIt<SyncData>(),
      ),
    );
}

/// iCloud on Apple platforms (uses the user's own iCloud — no extra account),
/// a local file elsewhere.
CloudFileStore _buildCloudFileStore() {
  if (Platform.isIOS || Platform.isMacOS) return const ICloudFileStore();
  return const LocalFileCloudStore();
}
