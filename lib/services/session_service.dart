import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _tokenKey = 'token';
  static const _userIdKey = 'userId';
  static const _emailKey = 'email';

  //stores session data locally (SharedPreferences)
  Future<void> saveSession({
    required String token,
    required String userId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_emailKey, email);
  }

  //gest locally stored session (SharedPreferences)
  Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);
    final userId = prefs.getString(_userIdKey);
    final email = prefs.getString(_emailKey);

    if (token == null || userId == null || email == null) {
      return null;
    }

    return {
      'token': token,
      'userId': userId,
      'email': email,
    };
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
  }

  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }
}