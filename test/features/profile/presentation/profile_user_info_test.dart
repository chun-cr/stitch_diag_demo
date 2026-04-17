import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/features/profile/domain/entities/profile_me_entity.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/profile_page.dart';
import 'package:stitch_diag_demo/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

void main() {
  testWidgets('profile page shows user info from /user/me response', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(430, 1200));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileMeProvider.overrideWith(
            (ref) async => const ProfileMeEntity(
              nickname: 'Amin',
              realName: 'Zhang San',
              countryCode: '+86',
              phone: '13812345678',
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amin'), findsOneWidget);
    expect(find.textContaining('Zhang San'), findsOneWidget);
    expect(find.textContaining('138****5678'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
