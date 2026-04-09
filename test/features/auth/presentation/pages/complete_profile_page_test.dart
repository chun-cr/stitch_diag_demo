import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/auth/presentation/pages/register_page.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

void main() {
  testWidgets('complete profile page shows skip nickname and gender fields', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompleteProfilePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('跳过'), findsOneWidget);
    expect(find.text('昵称'), findsOneWidget);
    expect(find.text('性别'), findsOneWidget);
    expect(find.text('手机号'), findsNothing);
    expect(find.text('密码'), findsNothing);
    expect(find.text('微信'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('complete profile avatar ring no longer breathes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompleteProfilePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    final ringFinder = find.byKey(const ValueKey('complete_profile_avatar_ring'));
    expect(ringFinder, findsOneWidget);
    final initialSize = tester.getSize(ringFinder);
    await tester.pump(const Duration(milliseconds: 1200));
    final laterSize = tester.getSize(ringFinder);

    expect(laterSize, equals(initialSize));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
