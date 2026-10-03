class DiscordUser {
  final String id;
  final String username;
  final String? globalName;
  final String? discriminator;
  final String? avatar;
  final String? email;
  final String accessToken;
  final String? refreshToken;
  final int? expiresAtMs;

  const DiscordUser({
    required this.id,
    required this.username,
    this.globalName,
    this.discriminator,
    this.avatar,
    this.email,
    required this.accessToken,
    this.refreshToken,
    this.expiresAtMs,
  });

  String get displayName => globalName ?? username;

  bool get isAccessTokenExpired {
    if (expiresAtMs == null) return false;
    // Treat tokens with under 60s left as expired.
    return DateTime.now().millisecondsSinceEpoch >= expiresAtMs! - 60000;
  }

  String get avatarUrl {
    if (avatar != null && avatar!.isNotEmpty) {
      final isGif = avatar!.startsWith('a_');
      final ext = isGif ? 'gif' : 'png';
      return 'https://cdn.discordapp.com/avatars/$id/$avatar.$ext?size=256';
    }
    // Migrated Discord usernames have discriminator "0"; the new default
    // avatar index is derived from the user ID: (id >> 22) % 6.
    final userId = int.tryParse(id);
    final defaultIndex = userId != null ? ((userId >> 22) % 6) : 0;
    return 'https://cdn.discordapp.com/embed/avatars/$defaultIndex.png';
  }

  DiscordUser copyWithTokens({
    required String accessToken,
    String? refreshToken,
    int? expiresAtMs,
  }) {
    return DiscordUser(
      id: id,
      username: username,
      globalName: globalName,
      discriminator: discriminator,
      avatar: avatar,
      email: email,
      accessToken: accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'global_name': globalName,
      'discriminator': discriminator,
      'avatar': avatar,
      'email': email,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at_ms': expiresAtMs,
    };
  }

  factory DiscordUser.fromJson(Map<String, dynamic> json, [String? fallbackToken]) {
    return DiscordUser(
      id: json['id'] as String,
      username: json['username'] as String,
      globalName: json['global_name'] as String?,
      discriminator: json['discriminator'] as String?,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      accessToken: (json['access_token'] as String?) ?? fallbackToken ?? '',
      refreshToken: json['refresh_token'] as String?,
      expiresAtMs: json['expires_at_ms'] as int?,
    );
  }
}
