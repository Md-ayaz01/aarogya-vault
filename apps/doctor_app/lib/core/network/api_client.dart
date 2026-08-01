import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform, SocketException;
import 'package:dio/dio.dart';
import '../database/local_db.dart';

// Global navigator key so the API interceptor can redirect without BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiClient {
  late final Dio _dio;

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (kReleaseMode) {
      throw StateError('API_BASE_URL must be supplied for release builds.');
    }
    return 'https://aarogya-vault.onrender.com/api/v1';
  }

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
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
            if (response.data['success'] == true) {
              response.data = response.data['data'];
            }
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // On 401, clear stale token and redirect to login
          if (e.response?.statusCode == 401 &&
              !_isRedirecting401 &&
              !(e.requestOptions.path.contains('session-check'))) {
            _isRedirecting401 = true;
            await LocalDB.deleteToken();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
            Future.delayed(const Duration(seconds: 2), () {
              _isRedirecting401 = false;
            });
          }
          return handler.next(e);
        },
      ),
    );
  }

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

  bool _isOfflineError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.error is SocketException;
  }
}
