import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import '../domain/discord_user.dart';

class DiscordAuthService {
  static const String clientId = '1555853808955822120';
  static const String redirectUri = 'https://studycrowd-51fdd.web.app/auth-callback';
  static const String customScheme = 'studycrowd';

  
  
  static const String _oauthFunctionUrl =
      'https://us-central1-studycrowd-51fdd.cloudfunctions.net/discordOauth';

  static const String _authUrl = 'https://discord.com/oauth2/authorize';
  static const String _userUrl = 'https://discord.com/api/users/@me';
  static const String _userStorageKey = 'discord_persisted_user';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String? _pendingState;

  
  
  static String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  
  static Future<void> saveUser(DiscordUser user) async {
    await _storage.write(key: _userStorageKey, value: jsonEncode(user.toJson()));
  }

  
  static Future<DiscordUser?> getSavedUser() async {
    try {
      final userJson = await _storage.read(key: _userStorageKey);
      if (userJson == null || userJson.isEmpty) return null;
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return DiscordUser.fromJson(map);
    } catch (e) {
      debugPrint('Failed to load saved Discord user: $e');
      return null;
    }
  }

  
  
  static Future<DiscordUser?> getValidSavedUser() async {
    final user = await getSavedUser();
    if (user == null) return null;

    if (!user.isAccessTokenExpired) {
      
      if (user.expiresAtMs == null) {
        final stillValid = await _validateAccessToken(user.accessToken);
        if (!stillValid) {
          return _tryRefreshOrClear(user);
        }
      }
      return user;
    }

    return _tryRefreshOrClear(user);
  }

  static Future<DiscordUser?> _tryRefreshOrClear(DiscordUser user) async {
    if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
      try {
        final refreshed = await _refreshAccessToken(user);
        await saveUser(refreshed);
        return refreshed;
      } catch (e) {
        debugPrint('Discord token refresh failed: $e');
      }
    }
    await signOut();
    return null;
  }

  static Future<bool> _validateAccessToken(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(_userUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<DiscordUser> _refreshAccessToken(DiscordUser user) async {
    final tokenData = await _callOAuthFunction({
      'action': 'refresh',
      'refresh_token': user.refreshToken,
    });
    final accessToken = tokenData['access_token'] as String;
    final newRefresh = tokenData['refresh_token'] as String?;
    final expiresIn = tokenData['expires_in'] as int?;
    return user.copyWithTokens(
      accessToken: accessToken,
      refreshToken: newRefresh,
      expiresAtMs: expiresIn != null
          ? DateTime.now().millisecondsSinceEpoch + expiresIn * 1000
          : null,
    );
  }

  
  static Future<void> signOut() async {
    final user = await getSavedUser();
    if (user != null && user.accessToken.isNotEmpty) {
      try {
        await _callOAuthFunction({'action': 'revoke', 'token': user.accessToken});
      } catch (e) {
        debugPrint('Token revoke failed (ignored): $e');
      }
    }
    await _storage.delete(key: _userStorageKey);
  }

  static Future<Map<String, dynamic>> _callOAuthFunction(
      Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(_oauthFunctionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final bodyText = response.body;
    Map<String, dynamic> data = {};
    if (bodyText.isNotEmpty) {
      try {
        data = jsonDecode(bodyText) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Unexpected OAuth function response: HTTP ${response.statusCode}');
      }
    }

    if (response.statusCode != 200) {
      final message = data['error_description'] ?? data['error'] ?? 'HTTP ${response.statusCode}';
      throw Exception('Discord OAuth: $message');
    }
    return data;
  }

  
  static Future<DiscordUser?> signInWithDiscord() async {
    final state = _generateState();
    _pendingState = state;

    final queryParams = {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': 'identify email',
      'state': state,
    };

    final uri = Uri.parse(_authUrl).replace(queryParameters: queryParams);

    try {
      
      final result = await FlutterWebAuth2.authenticate(
        url: uri.toString(),
        callbackUrlScheme: customScheme,
      );

      
      final responseUri = Uri.parse(result);

      final returnedState = responseUri.queryParameters['state'];
      if (_pendingState != null && returnedState != _pendingState) {
        throw Exception('OAuth state mismatch. Please try again.');
      }
      _pendingState = null;

      final code = responseUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        final error = responseUri.queryParameters['error_description'] ??
            responseUri.queryParameters['error'] ??
            'Authorization code not returned';
        throw Exception(error);
      }

      
      final tokenData = await _callOAuthFunction({
        'action': 'exchange',
        'code': code,
        'redirect_uri': redirectUri,
      });

      final accessToken = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String?;
      final expiresIn = tokenData['expires_in'] as int?;

      
      final userResponse = await http.get(
        Uri.parse(_userUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (userResponse.statusCode != 200) {
        debugPrint('Fetch profile failed: ${userResponse.body}');
        throw Exception('Failed to fetch Discord user: HTTP ${userResponse.statusCode}');
      }

      final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;
      final baseUser = DiscordUser.fromJson(userData, accessToken);
      final user = baseUser.copyWithTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAtMs: expiresIn != null
            ? DateTime.now().millisecondsSinceEpoch + expiresIn * 1000
            : null,
      );

      
      await saveUser(user);

      return user;
    } catch (e) {
      debugPrint('Discord OAuth error: $e');
      rethrow;
    }
  }
}
