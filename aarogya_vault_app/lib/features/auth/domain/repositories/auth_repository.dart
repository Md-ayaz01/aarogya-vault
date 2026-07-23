// lib/features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<String?> sendOtp(String phone);
  Future<bool> verifyOtp(String phone, String code);
  Future<bool> login({String? email, String? phone, String? password});
  Future<bool> register({String? email, String? phone, String? password});
  Future<bool> loginWithBiometrics(String token);
  Future<bool> verifyFirebaseOtp(String idToken);
  Future<bool> enrollBiometrics(String token);
  Future<bool> checkSession();
  Future<void> logout();
}
