import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/features/budgets/presentation/pages/budgets_page.dart';

void main() {
  testWidgets('budget dialog opens, accepts input, and returns the value',
      (WidgetTester tester) async {
    // Compile semantics every frame so a regression of the
    // `!semantics.parentDataDirty` assertion during the dialog's entrance
    // transition would fail this test.
    final SemanticsHandle handle = tester.ensureSemantics();
    double? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () async {
                captured = await showBudgetDialog(
                  context,
                  title: 'Groceries',
                  initial: null,
                  currency: 'EUR',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    // Tap the trigger to open the dialog.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The redesigned dialog must actually be on screen.
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Monthly limit'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Enter an amount and save.
    await tester.enterText(find.byType(TextField), '250');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(captured, 250);
    handle.dispose();
  });

  testWidgets('dialog with an existing budget shows Remove and lays out '
      'the action row without overflow', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    double? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () async {
                captured = await showBudgetDialog(
                  context,
                  title: 'Groceries',
                  initial: 100,
                  currency: 'EUR',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The Remove / Cancel / Save action row (the one that overflowed) renders.
    expect(find.text('Remove'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(captured, 0); // removing a budget returns 0
    handle.dispose();
  });
}
