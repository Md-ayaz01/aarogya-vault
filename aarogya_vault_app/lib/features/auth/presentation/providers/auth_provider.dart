import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_db.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/providers/api_provider.dart';
import 'package:aarogya_vault_app/features/auth/domain/repositories/auth_repository.dart';


class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final int? userId;

  AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.userId,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    int? userId,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userId: userId ?? this.userId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(isLoggedIn: LocalDB.isLoggedIn())) {
    _initUser();
  }

  Future<void> _initUser() async {
    if (state.isLoggedIn) {
      final cachedUserId = LocalDB.get(LocalDB.keyUserId);
      if (cachedUserId != null) {
        state = state.copyWith(userId: cachedUserId as int);
      }
    }
  }

  Future<String?> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepo = GetIt.I<AuthRepository>();
      final demoOtp = await authRepo.sendOtp(phone);
      if (demoOtp != null) {
        state = state.copyWith(isLoading: false);
        return demoOtp;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to send OTP.');
        return null;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to send OTP. Please try again.');
    }
    return null;
  }

  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepo = GetIt.I<AuthRepository>();
      final success = await authRepo.verifyOtp(phone, code);
      if (success) {
        // Assume token and userId are persisted inside repository or elsewhere
        // For now, we fetch session check to update state
        await checkSession();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Invalid OTP. Please try again.');
    }
    return false;
  }

  Future<bool> checkSession() async {
    final token = await LocalDB.getToken();
    if (token == null) {
      state = AuthState(isLoggedIn: false);
      return false;
    }
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/auth/session-check');
      if (response.statusCode == 200) {
        final userId = response.data['user_id'];
        await LocalDB.save(LocalDB.keyUserId, userId);
        state = AuthState(isLoggedIn: true, userId: userId);
        return true;
      }
    } catch (e) {
      // If session-check fails (endpoint missing, network error, etc.),
      // keep the token — don't force logout. The token may still be valid
      // for other endpoints. Only truly log out if we have no token at all.
      debugPrint('checkSession error (non-fatal): $e');
      // Mark as logged in since we have a token
      final cachedUserId = LocalDB.get(LocalDB.keyUserId);
      state = AuthState(isLoggedIn: true, userId: cachedUserId as int?);
      return true;
    }
    return false;
  }

  Future<bool> login({String? email, String? phone, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepo = GetIt.I<AuthRepository>();
      final success = await authRepo.login(email: email, phone: phone, password: password);
      if (success) {
        await checkSession();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Invalid credentials. Please try again.');
    }
    return false;
  }

  Future<bool> loginWithBiometrics(String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepo = GetIt.I<AuthRepository>();
      final success = await authRepo.loginWithBiometrics(token);
      if (success) {
        await checkSession();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Biometric authorization failed on server.');
    }
    return false;
  }

  Future<bool> register({String? email, String? phone, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/auth/register', data: {
        'email': email,
        'phone': phone,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        final userId = response.data['user_id'];
        
        await LocalDB.saveToken(token);
        await LocalDB.save(LocalDB.keyUserId, userId);
        
        state = AuthState(isLoggedIn: true, isLoading: false, userId: userId);
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Registration failed. Email or phone may exist.');
    }
    return false;
  }

  Future<bool> verifyAadhaar(String aadhaarNum) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/auth/aadhaar-verify', data: null, queryParameters: {'aadhaar_num': aadhaarNum});
      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Aadhaar verification failed.');
    }
    return false;
  }

  Future<bool> verifyFirebaseOtp(String idToken) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepo = GetIt.I<AuthRepository>();
      final success = await authRepo.verifyFirebaseOtp(idToken);
      if (success) {
        await checkSession();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Firebase OTP verification failed.');
    }
    return false;
  }

  Future<bool> verifySupabaseSession(String accessToken) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/auth/supabase/session', data: {
        'access_token': accessToken,
      });
      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        final userId = response.data['user_id'];
        
        await LocalDB.saveToken(token.toString());
        await LocalDB.save(LocalDB.keyUserId, userId);
        
        state = AuthState(isLoggedIn: true, isLoading: false, userId: userId);
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Supabase session verification failed.');
    }
    return false;
  }

  Future<bool> enrollBiometrics(String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/auth/biometric-setup', queryParameters: {
        'biometric_token': token,
      });
      state = state.copyWith(isLoading: false);
      if (response.statusCode == 200) {
        await LocalDB.save('biometric_token_key', token);
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to link biometrics with server.');
    }
    return false;
  }

  Future<bool> loginWithStoredBiometrics() async {
    final token = LocalDB.get('biometric_token_key');
    if (token == null) {
      state = state.copyWith(errorMessage: 'Biometric credentials not found. Please log in with password/OTP first.');
      return false;
    }
    return await loginWithBiometrics(token.toString());
  }

  Future<void> logout() async {
    await LocalDB.clearAll();
    state = AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
