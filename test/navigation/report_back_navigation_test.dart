import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    setPreviewAuthenticated(false);
  });

  testWidgets('从首页底部报告进入后，点击返回应回到首页内容', (tester) async {
    setPreviewAuthenticated(true);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('AI 望诊入口'), findsOneWidget);
    expect(find.text('总览'), findsNothing);

    await tester.tap(find.text('报告'));
    await tester.pumpAndSettle();

    expect(find.text('总览'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
    await tester.pumpAndSettle();

    expect(find.text('AI 望诊入口'), findsOneWidget);
    expect(find.text('总览'), findsNothing);
  });
}
