import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'jwt';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> logout() async {
    await clearToken();
  }

  static Map<String, dynamic>? _decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);
      return payloadMap;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getRole() async {
    final token = await getToken();
    if (token == null) return null;
    final payload = _decodePayload(token);
    if (payload == null) return null;
    final role = payload['roles'];
    if (role is String) return role;
    if (role is List && role.isNotEmpty) return role[0].toString();
    return null;
  }
}
