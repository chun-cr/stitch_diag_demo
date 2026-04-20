import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/share_referral_state.dart';

class ShareReferralStore {
  static const _stateKey = 'share_referral_state';

  Future<ShareReferralState> loadState() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_stateKey);
    if (raw == null || raw.isEmpty) {
      return const ShareReferralState();
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const ShareReferralState();
    }

    return ShareReferralState.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<ShareReferralState> saveState(ShareReferralState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_stateKey, jsonEncode(state.toJson()));
    return state;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_stateKey);
  }
}
