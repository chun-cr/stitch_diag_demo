import 'package:shared_preferences/shared_preferences.dart';

class LoginPasswordStore {
  static const _hasPasswordKey = 'account_has_login_password';
  static const _promptPendingKey = 'account_password_setup_prompt_pending';

  Future<bool> hasLoginPassword() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_hasPasswordKey) ?? false;
  }

  Future<void> setHasLoginPassword(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hasPasswordKey, value);
  }

  Future<void> markPasswordSetupPromptPending() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_promptPendingKey, true);
  }

  Future<bool> consumePasswordSetupPrompt() async {
    final preferences = await SharedPreferences.getInstance();
    final pending = preferences.getBool(_promptPendingKey) ?? false;
    if (pending) {
      await preferences.setBool(_promptPendingKey, false);
    }
    return pending;
  }
}
