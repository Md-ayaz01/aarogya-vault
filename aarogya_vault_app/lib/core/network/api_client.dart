import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform, SocketException, File;
import 'package:dio/dio.dart';
import '../database/local_db.dart';

// Global navigator key so the API interceptor can redirect without BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiClient {
  late final Dio _dio;

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (kReleaseMode) {
      if (kIsWeb) {
        // Fall back to the published Render API for web release builds when the
        // Dart define was not provided. This ensures the deployed web app can
        // still reach the live backend for OTP delivery.
        return 'https://aarogya-vault.onrender.com/api/v1';
      }
      throw StateError('API_BASE_URL must be supplied for release builds.');
    }
    return 'https://aarogya-vault.onrender.com/api/v1';
  }

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await LocalDB.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.data is Map && response.data.containsKey('success')) {
            if (response.data['success'] == true && response.data.containsKey('data')) {
              response.data = response.data['data'];
            }
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // On 401, clear stale token and redirect to splash — but only ONCE.
          // Without the guard, multiple inflight requests each fire a redirect.
          if (e.response?.statusCode == 401 &&
              !_isRedirecting401 &&
              !(e.requestOptions.path.contains('session-check'))) {
            _isRedirecting401 = true;
            await LocalDB.deleteToken();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/splash',
              (route) => false,
            );
            // Reset flag after navigation is handled
            Future.delayed(const Duration(seconds: 2), () {
              _isRedirecting401 = false;
            });
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Guard: prevent multiple simultaneous 401 redirects
  static bool _isRedirecting401 = false;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParameters);
      return res;
    } on DioException catch (e) {
      if (_isOfflineError(e)) {
        final cachedData = LocalDB.get(path);
        if (cachedData != null) {
          return Response(
            requestOptions: e.requestOptions,
            data: cachedData,
            statusCode: 200,
            statusMessage: 'Loaded from offline cache',
          );
        }
      }
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> uploadFile(
    String path,
    String? filePath,
    String title,
    String date,
    String type, {
    List<int>? bytes,
    String? fileName,
  }) async {
    try {
      final MultipartFile multipartFile;
      if (kIsWeb) {
        if (bytes == null || fileName == null) {
          throw Exception("Web upload requires bytes and fileName");
        }
        multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        if (filePath == null) {
          throw Exception("Mobile upload requires filePath");
        }
        final file = File(filePath);
        final name = fileName ?? file.path.split('/').last;
        multipartFile = await MultipartFile.fromFile(filePath, filename: name);
      }

      final formData = FormData.fromMap({
        'title': title,
        'date': date,
        'report_type': type,
        'file': multipartFile,
      });

      return await _dio.post(path, data: formData);
    } catch (e) {
      rethrow;
    }
  }

  bool _isOfflineError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.error is SocketException;
  }
}
