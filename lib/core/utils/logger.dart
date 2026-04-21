import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message) {
    developer.log(message, name: 'AppLogger');
    debugPrintSynchronously('[AppLogger] $message');
    // ignore: avoid_print
    print('[AppLogger] $message');
  }
}
