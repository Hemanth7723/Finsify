import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finsify/main.dart';
import 'package:finsify/theme/finsify_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows loading then profile setup', (tester) async {
    await tester.pumpWidget(const FinsifyApp());
    expect(find.text('COSMIC BUDGET'), findsOneWidget);
    expect(find.text('Loading Expense Tracker...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Welcome to Cosmic Budget'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('dashboard navigation opens finance screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDashboard(
          profile: const ProfileData(name: 'Taylor', email: '', bio: ''),
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TOTAL EXPENSES'), findsOneWidget);
    await tester.tap(find.text('Invest'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Investments'), findsOneWidget);
    await tester.tap(find.text('Loans'));
    await tester.pumpAndSettle();
    expect(find.text('Loans & EMI'), findsOneWidget);
    await tester.tap(find.text('Bills'));
    await tester.pumpAndSettle();
    expect(find.text('Bills to pay'), findsOneWidget);
    await tester.tap(find.text('Loans'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text('Invest'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text('Bills'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Invest'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('primary-add-action')));
    await tester.pumpAndSettle();
    expect(find.text('Add investment'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('primary-add-action')));
    await tester.pumpAndSettle();
    expect(find.text('Manual Transaction Ledger'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme is applied to dashboard dialogs and inputs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinsifyTheme(dark: true),
        darkTheme: buildFinsifyTheme(dark: true),
        home: ExpenseDashboard(
          profile: const ProfileData(name: 'Taylor', email: '', bio: ''),
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, FinsifyColors.dark.background);
    await tester.tap(find.byKey(const ValueKey('primary-add-action')));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog).last);
    expect(dialog.backgroundColor, FinsifyColors.dark.surfaceRaised);
    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.decoration?.fillColor, FinsifyColors.dark.surfaceInset);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Invest'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('primary-add-action')));
    await tester.pumpAndSettle();
    expect(find.text('Add investment'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Investments')))
          .extension<FinsifyColors>()
          ?.surface,
      FinsifyColors.dark.surface,
    );
    expect(
      Theme.of(tester.element(find.byType(TextField).first))
          .inputDecorationTheme
          .fillColor,
      FinsifyColors.dark.surfaceInset,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile theme preview rebuilds safely before applying', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    bool? selectedDarkMode;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinsifyTheme(dark: false),
        home: ExpenseDashboard(
          profile: const ProfileData(name: 'Taylor', email: '', bio: ''),
          onThemeChanged: (enabled) => selectedDarkMode = enabled,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Secure Identity Controls'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Dark Mode Enabled'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();
    expect(selectedDarkMode, isTrue);
    expect(tester.takeException(), isNull);
  });
}
