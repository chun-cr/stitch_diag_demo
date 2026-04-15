import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/core/platform/app_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app/info');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    AppIdentity.resetForTest();
  });

  test('loads native app id once and caches it', () async {
    var callCount = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      callCount++;
      expect(call.method, 'getAppId');
      return 'com.huaji.myapp.dev';
    });

    final firstResult = await AppIdentity.initialize();
    final secondResult = await AppIdentity.initialize();

    expect(firstResult, 'com.huaji.myapp.dev');
    expect(secondResult, 'com.huaji.myapp.dev');
    expect(AppIdentity.currentAppId, 'com.huaji.myapp.dev');
    expect(callCount, 1);
  });

  test('falls back when native app id is unavailable', () async {
    final result = await AppIdentity.initialize();

    expect(result, AppIdentity.fallbackAppId);
    expect(AppIdentity.currentAppId, AppIdentity.fallbackAppId);
  });
}
