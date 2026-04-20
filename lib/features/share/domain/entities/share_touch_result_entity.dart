class ShareTouchResultEntity {
  const ShareTouchResultEntity({
    required this.inviteTicket,
    required this.expireTime,
  });

  final String inviteTicket;
  final String expireTime;

  bool get hasInviteTicket => inviteTicket.isNotEmpty;

  factory ShareTouchResultEntity.fromJson(Map<String, dynamic> json) {
    return ShareTouchResultEntity(
      inviteTicket: _readString(json['inviteTicket']),
      expireTime: _readString(json['expireTime']),
    );
  }
}

String _readString(dynamic value) {
  return value == null ? '' : value.toString().trim();
}
