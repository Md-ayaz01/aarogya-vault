// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_db.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;

  AuthRepositoryImpl({required this.apiClient});

  @override
  Future<String?> sendOtp(String phone) async {
    final response = await apiClient.post('/auth/send-otp', data: {'phone': phone});
    if (response.statusCode == 200) {
      return response.data['demo_otp']?.toString();
    }
    return null;
  }

  @override
  Future<bool> verifyOtp(String phone, String code) async {
    final response = await apiClient.post('/auth/verify-otp', data: {'phone': phone, 'code': code});
    if (response.statusCode == 200) {
      final token = response.data['access_token'];
      final userId = response.data['user_id'];
      if (token != null) {
        await LocalDB.saveToken(token.toString());
      }
      if (userId != null) {
        await LocalDB.save(LocalDB.keyUserId, userId);
      }
      return true;
    }
    return false;
  }

  @override
  Future<bool> login({String? email, String? phone, String? password}) async {
    final response = await apiClient.post('/auth/login', data: {
      'email': email,
      'phone': phone,
      'password': password,
    });
    if (response.statusCode == 200) {
      // Save the JWT token and user_id so subsequent requests are authenticated
      final token = response.data['access_token'];
      final userId = response.data['user_id'];
      if (token != null) {
        await LocalDB.saveToken(token.toString());
      }
      if (userId != null) {
        await LocalDB.save(LocalDB.keyUserId, userId);
      }
      return true;
    }
    return false;
  }

  @override
  Future<bool> register({String? email, String? phone, String? password}) async {
    final response = await apiClient.post('/auth/register', data: {
      'email': email,
      'phone': phone,
      'password': password,
    });
    return response.statusCode == 200;
  }

  @override
  Future<bool> loginWithBiometrics(String token) async {
    final response = await apiClient.post('/auth/login', data: {'biometric_token': token});
    return response.statusCode == 200;
  }

  @override
  Future<bool> verifyFirebaseOtp(String idToken) async {
    final response = await apiClient.post('/auth/verify-firebase-otp', data: {'id_token': idToken});
    if (response.statusCode == 200) {
      final token = response.data['access_token'];
      final userId = response.data['user_id'];
      if (token != null) {
        await LocalDB.saveToken(token.toString());
      }
      if (userId != null) {
        await LocalDB.save(LocalDB.keyUserId, userId);
      }
      return true;
    }
    return false;
  }

  @override
  Future<bool> enrollBiometrics(String token) async {
    final response = await apiClient.post('/auth/biometric-setup', queryParameters: {'biometric_token': token});
    return response.statusCode == 200;
  }

  @override
  Future<bool> checkSession() async {
    try {
      final response = await apiClient.get('/auth/session-check');
      return response.statusCode == 200;
    } catch (_) {
      // session-check endpoint may not exist; fall back to token presence
      final token = await LocalDB.getToken();
      return token != null;
    }
  }

  @override
  Future<void> logout() async {
    // No backend action needed; clear local storage handled elsewhere
    return;
  }
}
