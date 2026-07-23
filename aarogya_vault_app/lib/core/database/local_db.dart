import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalDB {
  static const String _authBoxName = 'auth_box';
  static const String _cacheBoxName = 'cache_box';
  
  static const String keyToken = 'jwt_token';
  static const String keyUserId = 'user_id';
  static const String keyProfile = 'cached_profile';
  static const String keyReports = 'cached_reports';
  static const String keyReminders = 'cached_reminders';
  static const String keyHistory = 'cached_history';
  
  static final _secureStorage = const FlutterSecureStorage();

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_authBoxName);
    await Hive.openBox(_cacheBoxName);
  }

  static Box get _authBox => Hive.box(_authBoxName);
  static Box get _cacheBox => Hive.box(_cacheBoxName);

  // Secure Token storage
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: keyToken, value: token);
    await _authBox.put(keyToken, true); // Flag indicating logged in
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: keyToken);
  }

  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: keyToken);
    await _authBox.delete(keyToken);
  }

  static bool isLoggedIn() {
    return _authBox.get(keyToken, defaultValue: false) == true;
  }

  // Generic Cache storage
  static Future<void> save(String key, dynamic value) async {
    if (value is Map || value is List) {
      await _cacheBox.put(key, jsonEncode(value));
    } else {
      await _cacheBox.put(key, value);
    }
  }

  static dynamic get(String key, {dynamic defaultValue}) {
    final val = _cacheBox.get(key, defaultValue: defaultValue);
    if (val is String && (val.startsWith('{') || val.startsWith('['))) {
      try {
        return jsonDecode(val);
      } catch (e) {
        return val;
      }
    }
    return val;
  }

  static Future<void> clearAll() async {
    await _authBox.clear();
    await _cacheBox.clear();
    await _secureStorage.deleteAll();
  }
}
