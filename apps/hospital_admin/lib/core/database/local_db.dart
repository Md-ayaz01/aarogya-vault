import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalDB {
  static const _storage = FlutterSecureStorage();
  static const keyToken = 'jwt_token';
  static const keyRole = 'user_role';
  static const keyUserId = 'user_id';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: keyToken);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: keyToken);
  }

  static Future<void> saveRole(String role) async {
    await _storage.write(key: keyRole, value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: keyRole);
  }

  static Future<void> save(String key, dynamic value) async {
    await _storage.write(key: key, value: value.toString());
  }

  static String? get(String key) {
    return null; // fallback runtime
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
