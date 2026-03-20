// ignore_for_file: uri_does_not_exist, uri_has_not_been_generated, override_on_non_overriding_member
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  bool build() {
    return false; // Not authenticated by default
  }
}
