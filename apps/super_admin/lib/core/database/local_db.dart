import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalDB {
  static final LocalDB _instance = LocalDB._internal();
  factory LocalDB() => _instance;
  LocalDB._internal();

  final _storage = const FlutterSecureStorage();

  static const String _keyToken = 'jwt_token';
  static const String _keyRole = 'user_role';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: _keyRole, value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _keyRole);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
