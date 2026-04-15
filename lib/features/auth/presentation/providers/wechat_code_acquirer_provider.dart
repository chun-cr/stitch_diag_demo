import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class WechatCodeAcquirer {
  const WechatCodeAcquirer();

  Future<String?> acquireWechatCode();
}

class UnsupportedWechatCodeAcquirer implements WechatCodeAcquirer {
  const UnsupportedWechatCodeAcquirer();

  @override
  Future<String?> acquireWechatCode() {
    throw UnimplementedError(
      'Implement WechatCodeAcquirer.acquireWechatCode() for the target platform.',
    );
  }
}

final wechatCodeAcquirerProvider = Provider<WechatCodeAcquirer>(
  (ref) => const UnsupportedWechatCodeAcquirer(),
);
