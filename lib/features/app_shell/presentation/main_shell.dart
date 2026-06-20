import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/features/budgets/presentation/pages/budgets_page.dart';
import 'package:jeb/features/plans/presentation/pages/plans_page.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:jeb/features/settings/presentation/pages/settings_page.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:jeb/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:jeb/features/transactions/presentation/pages/home_page.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// App shell with a bottom navigation bar and a docked center "Add" button.
/// Hosts the primary destinations: Home · Budgets · Plans · Settings.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransactionsCubit>(
      create: (_) => getIt<TransactionsCubit>()..load(),
      child: const _ShellScaffold(),
    );
  }
}

class _ShellScaffold extends StatefulWidget {
  const _ShellScaffold();

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back up as the user leaves the app (in addition to the on-open sync).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      context.read<SettingsCubit>().backupOnBackground();
    }
  }

  static const List<Widget> _pages = <Widget>[
    HomeView(),
    BudgetsPage(),
    PlansPage(),
    SettingsPage(),
  ];

  void _select(int index) {
    setState(() => _index = index);
    if (index == 0) {
      context.read<TransactionsCubit>().refresh();
    }
  }

  Future<void> _addTransaction() async {
    HapticFeedback.selectionClick();
    final TransactionsCubit transactionsCubit =
        context.read<TransactionsCubit>();
    final String currency =
        context.read<SettingsCubit>().state.settings.defaultCurrencyCode;

    final result = await getIt<GetCategories>()(const NoParams());
    final List<Category> categories =
        result.fold((_) => const <Category>[], (List<Category> c) => c);
    if (!mounted) return;

    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddTransactionPage(
          categories: categories,
          defaultCurrency: currency,
        ),
      ),
    );
    if (saved ?? false) {
      await transactionsCubit.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: _AddButton(
        onTap: _addTransaction,
        scheme: scheme,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 9,
        height: 68,
        padding: EdgeInsets.zero,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _NavItem(
                icon: PhosphorIcons.house(),
                activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                label: 'Home',
                selected: _index == 0,
                onTap: () => _select(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: PhosphorIcons.wallet(),
                activeIcon: PhosphorIcons.wallet(PhosphorIconsStyle.fill),
                label: 'Budgets',
                selected: _index == 1,
                onTap: () => _select(1),
              ),
            ),
            const Expanded(child: SizedBox()),
            Expanded(
              child: _NavItem(
                icon: PhosphorIcons.target(),
                activeIcon: PhosphorIcons.target(PhosphorIconsStyle.fill),
                label: 'Plans',
                selected: _index == 2,
                onTap: () => _select(2),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: PhosphorIcons.gearSix(),
                activeIcon: PhosphorIcons.gearSix(PhosphorIconsStyle.fill),
                label: 'Settings',
                selected: _index == 3,
                onTap: () => _select(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient circular "Add transaction" button docked into the nav bar notch.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.scheme});

  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      shape: const CircleBorder(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      highlightElevation: 0,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              scheme.primary,
              Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.55),
                scheme.primary,
              ),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          PhosphorIcons.plus(PhosphorIconsStyle.bold),
          color: scheme.onPrimary,
          size: 26,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return InkResponse(
      onTap: onTap,
      radius: 44,
      highlightColor: Colors.transparent,
      splashColor: scheme.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(selected ? activeIcon : icon, color: color, size: 23),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
