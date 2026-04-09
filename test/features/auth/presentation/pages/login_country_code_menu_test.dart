import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/main.dart';

Future<void> _pumpLoginPage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  setPreviewAuthenticated(false);
  await tester.binding.setSurfaceSize(const Size(1280, 2400));
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pump(const Duration(milliseconds: 900));
  expect(find.byType(LoginPage), findsOneWidget);
}

Future<void> _openCountrySelector(WidgetTester tester) async {
  final menuAnchor = tester.widget<MenuAnchor>(find.byType(MenuAnchor));
  menuAnchor.controller?.open();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets(
    'country selector prefix is visible before focusing phone field',
    (tester) async {
      await _pumpLoginPage(tester);

      expect(
        find.byKey(const ValueKey('country_code_menu_trigger')),
        findsOneWidget,
      );
      expect(find.text('+86'), findsOneWidget);
      expect(find.text('🇨🇳'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'country selector opens as lightweight menu instead of bottom sheet',
    (tester) async {
      await _pumpLoginPage(tester);

      await _openCountrySelector(tester);

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('选择国家/地区码'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('country selector does not show trailing selected check icon', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);

    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('selecting a country updates the prefix and closes the menu', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);
    await tester.tap(find.text('+44'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('+44'), findsOneWidget);
    expect(find.text('英国'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('country selector uses a shadowed animated popup surface', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);

    final surfaceFinder = find.byKey(
      const ValueKey('country_code_menu_surface'),
    );
    final transitionFinder = find.byKey(
      const ValueKey('country_code_menu_transition'),
    );

    expect(surfaceFinder, findsOneWidget);
    expect(transitionFinder, findsOneWidget);

    final surface = tester.widget<Container>(surfaceFinder);
    final decoration = surface.decoration as BoxDecoration;

    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
    expect(decoration.boxShadow!.first.blurRadius, greaterThanOrEqualTo(12));
    expect(decoration.boxShadow!.first.color.a, lessThanOrEqualTo(0.08));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
