import 'auth_session_entity.dart';

class WechatMiniProgramAuthResultEntity {
  final String authStatus;
  final AuthSessionEntity? session;
  final String? globalUserId;
  final String? phoneNumber;

  const WechatMiniProgramAuthResultEntity({
    required this.authStatus,
    required this.session,
    required this.globalUserId,
    this.phoneNumber,
  });

  bool get hasSession => session != null;
}
