import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';

class AuthSessionStore {
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _tokenTypeKey = 'auth_token_type';
  static const _expiresInKey = 'auth_expires_in';
  static const _scopeKey = 'auth_scope';

  Future<void> saveSession(AuthSessionEntity session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, session.accessToken);
    await preferences.setString(_refreshTokenKey, session.refreshToken);
    await preferences.setString(_tokenTypeKey, session.tokenType);
    await preferences.setInt(_expiresInKey, session.expiresIn);
    await preferences.setString(_scopeKey, session.scope);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_tokenTypeKey);
    await preferences.remove(_expiresInKey);
    await preferences.remove(_scopeKey);
  }

  Future<bool> hasSession() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getString(_accessTokenKey) ?? '').isNotEmpty;
  }

  Future<String?> refreshToken() async {
    final preferences = await SharedPreferences.getInstance();
    final refreshToken = preferences.getString(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }
    return refreshToken;
  }

  Future<String?> authorizationHeader() async {
    final preferences = await SharedPreferences.getInstance();
    final accessToken = preferences.getString(_accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final tokenType = preferences.getString(_tokenTypeKey);
    final normalizedType = (tokenType == null || tokenType.isEmpty)
        ? 'Bearer'
        : tokenType;

    return '$normalizedType $accessToken';
  }
}
