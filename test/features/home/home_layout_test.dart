import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/features/home/domain/home_section.dart';

void main() {
  group('HomeLayout', () {
    test('defaults show every section in declaration order', () {
      final HomeLayout layout = HomeLayout.defaults;
      expect(layout.order, HomeSection.values);
      expect(layout.hidden, isEmpty);
      expect(layout.visible, HomeSection.values);
    });

    test('visible skips hidden sections but keeps order', () {
      final HomeLayout layout = HomeLayout(
        order: const <HomeSection>[
          HomeSection.recent,
          HomeSection.summary,
          HomeSection.accounts,
        ],
        hidden: const <HomeSection>{HomeSection.summary},
      );
      expect(layout.visible, <HomeSection>[
        HomeSection.recent,
        HomeSection.accounts,
      ]);
      expect(layout.isEnabled(HomeSection.summary), isFalse);
      expect(layout.isEnabled(HomeSection.recent), isTrue);
    });

    test('serialize/parse round-trips order and hidden state', () {
      final HomeLayout layout = HomeLayout(
        order: const <HomeSection>[
          HomeSection.recent,
          HomeSection.accounts,
          HomeSection.plans,
          HomeSection.spending,
          HomeSection.summary,
        ],
        hidden: const <HomeSection>{HomeSection.plans, HomeSection.spending},
      );
      final HomeLayout back = HomeLayout.parse(layout.serialize());
      expect(back.order, layout.order);
      expect(back.hidden, layout.hidden);
    });

    test('serialize marks hidden sections with a leading dash', () {
      final HomeLayout layout = HomeLayout(
        order: const <HomeSection>[HomeSection.summary, HomeSection.recent],
        hidden: const <HomeSection>{HomeSection.recent},
      );
      // Only these two are encoded explicitly; the rest are appended on parse.
      expect(layout.serialize(), startsWith('summary,-recent'));
    });

    test('parse(null) falls back to defaults', () {
      expect(HomeLayout.parse(null), HomeLayout.defaults);
      expect(HomeLayout.parse(''), HomeLayout.defaults);
    });

    test('parse appends sections missing from storage, enabled', () {
      // Only two sections stored (e.g. saved before others were added).
      final HomeLayout layout = HomeLayout.parse('accounts,-summary');
      expect(layout.order.first, HomeSection.accounts);
      expect(layout.hidden, <HomeSection>{HomeSection.summary});
      // Every section still present, and the appended ones are enabled.
      expect(layout.order.toSet(), HomeSection.values.toSet());
      expect(layout.isEnabled(HomeSection.recent), isTrue);
      expect(layout.isEnabled(HomeSection.plans), isTrue);
    });

    test('parse ignores unknown/duplicate tokens', () {
      final HomeLayout layout = HomeLayout.parse('summary,bogus,summary,recent');
      expect(layout.order.where((HomeSection s) => s == HomeSection.summary),
          hasLength(1));
      expect(layout.order.toSet(), HomeSection.values.toSet());
    });
  });
}
