import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/login_page.dart';
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
  await tester.tap(find.byKey(const ValueKey('country_code_menu_trigger')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
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

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('country selector opens as Cupertino-style picker page', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);

    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byKey(const ValueKey('country_code_picker_page')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('country_code_picker_search')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('country selector shows selected check mark in picker page', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('country_code_picker_item_+86')),
        matching: find.byIcon(CupertinoIcons.check_mark),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('selecting a country updates the prefix and closes the picker', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);
    await tester.tap(
      find.byKey(const ValueKey('country_code_picker_item_+44')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(
      find.byKey(const ValueKey('country_code_menu_trigger')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('country_code_menu_trigger')),
        matching: find.text('+44'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('country selector search filters the list', (tester) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);
    await tester.enterText(
      find.byKey(const ValueKey('country_code_picker_search')),
      'japan',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('country_code_picker_item_+81')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('country_code_picker_item_+49')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
