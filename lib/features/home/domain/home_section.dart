import 'package:equatable/equatable.dart';

/// The configurable sections of the home dashboard, in their default order.
enum HomeSection {
  summary,
  accounts,
  plans,
  spending,
  recent;

  String get storageValue => name;

  static HomeSection? fromStorage(String value) {
    for (final HomeSection s in HomeSection.values) {
      if (s.name == value) return s;
    }
    return null;
  }

  String get label => switch (this) {
        HomeSection.summary => 'Monthly summary',
        HomeSection.accounts => 'Accounts',
        HomeSection.plans => 'Plans',
        HomeSection.spending => 'Spending by category',
        HomeSection.recent => 'Recent transactions',
      };

  String get description => switch (this) {
        HomeSection.summary => 'Income, expense and balance for the month',
        HomeSection.accounts => 'Your wallet balances at a glance',
        HomeSection.plans => 'Progress toward your goals',
        HomeSection.spending => 'Where this month\'s money went',
        HomeSection.recent => 'Your latest transactions',
      };
}

/// A user's home layout: the order of every [HomeSection] plus which are hidden.
/// Persisted per device; sections absent from storage (e.g. added in an app
/// update) are appended, enabled, so the home never silently drops a feature.
class HomeLayout extends Equatable {
  const HomeLayout({required this.order, required this.hidden});

  final List<HomeSection> order;
  final Set<HomeSection> hidden;

  static HomeLayout get defaults => HomeLayout(
        order: List<HomeSection>.from(HomeSection.values),
        hidden: const <HomeSection>{},
      );

  /// The sections to render, in order, skipping the hidden ones.
  List<HomeSection> get visible =>
      order.where((HomeSection s) => !hidden.contains(s)).toList();

  bool isEnabled(HomeSection s) => !hidden.contains(s);

  HomeLayout copyWith({List<HomeSection>? order, Set<HomeSection>? hidden}) =>
      HomeLayout(order: order ?? this.order, hidden: hidden ?? this.hidden);

  /// Encodes the full order with a leading '-' marking hidden sections, e.g.
  /// "summary,accounts,-plans,spending,recent".
  String serialize() => order
      .map((HomeSection s) => hidden.contains(s) ? '-${s.name}' : s.name)
      .join(',');

  factory HomeLayout.parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return HomeLayout.defaults;

    final List<HomeSection> order = <HomeSection>[];
    final Set<HomeSection> hidden = <HomeSection>{};
    for (final String part in raw.split(',')) {
      final bool isHidden = part.startsWith('-');
      final String name = isHidden ? part.substring(1) : part;
      final HomeSection? section = HomeSection.fromStorage(name);
      if (section != null && !order.contains(section)) {
        order.add(section);
        if (isHidden) hidden.add(section);
      }
    }
    // Append any sections missing from storage (forward compatibility).
    for (final HomeSection s in HomeSection.values) {
      if (!order.contains(s)) order.add(s);
    }
    return HomeLayout(order: order, hidden: hidden);
  }

  @override
  List<Object?> get props => <Object?>[order, hidden];
}
