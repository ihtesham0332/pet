import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/app_constants.dart';
import 'network_exceptions.dart';
import 'token_storage.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage _storage = TokenStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.cloudApiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      _ConnectivityInterceptor(),
      _AuthInterceptor(_storage),
      _RetryInterceptor(
        dio: _dio,
        maxRetries: AppConstants.maxRetries,
        retryDelay: AppConstants.retryDelay,
      ),
      _LoggingInterceptor(),
    ]);
  }

  /// POST request with automatic error handling.
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  /// GET request with automatic error handling.
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      return await _dio.get(path, queryParameters: params);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  /// PUT request with automatic error handling.
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  /// DELETE request with automatic error handling.
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }
}

// ── Connectivity Interceptor ───────────────────────────────────────
// Checks if the device has any network connectivity BEFORE sending
// the request, so we fail fast with a clear message instead of
// waiting 30 seconds for a timeout.
class _ConnectivityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'No internet connection',
          ),
        );
      }
    } catch (_) {
      // If connectivity check itself fails, let the request proceed
      // and let the actual network call determine the outcome.
    }
    handler.next(options);
  }
}

// ── Retry Interceptor ──────────────────────────────────────────────
// Automatically retries failed requests on connection errors and
// timeouts with exponential backoff. This prevents transient network
// hiccups from crashing the app.
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  _RetryInterceptor({
    required this.dio,
    required this.maxRetries,
    required this.retryDelay,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only retry on connection-related errors, not on 4xx/5xx responses
    if (_shouldRetry(err)) {
      final extra = err.requestOptions.extra;
      final retryCount = (extra['retryCount'] as int?) ?? 0;

      if (retryCount < maxRetries) {
        final nextRetry = retryCount + 1;
        final delay = retryDelay * (1 << retryCount); // Exponential backoff: 2s, 4s, 8s

        if (kDebugMode) {
          print('[API] Retry $nextRetry/$maxRetries after ${delay.inSeconds}s → ${err.requestOptions.path}');
        }

        await Future.delayed(delay);

        // Clone the request with updated retry count
        final opts = err.requestOptions;
        opts.extra['retryCount'] = nextRetry;

        try {
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          // If retry also fails, continue to next retry or final error
          return super.onError(retryError, handler);
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.unknown &&
            (err.error is SocketException || err.error is TimeoutException));
  }
}

// ── Auth Interceptor ───────────────────────────────────────────────
// Attaches the JWT token to every request automatically.
class _AuthInterceptor extends Interceptor {
  final TokenStorage _storage;
  bool _retrying = false;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_retrying) {
      _retrying = true;
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await Dio(BaseOptions()).fetch(opts);
          _retrying = false;
          return handler.resolve(response);
        } catch (_) {}
      }
      _retrying = false;
    }
    handler.next(err);
  }
}

// ── Logging Interceptor ────────────────────────────────────────────
// Only logs in debug mode to keep release builds clean.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('[API] ${options.method} ${options.baseUrl}${options.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('[API] ✅ ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('[API] ❌ ${err.type.name}: ${err.message ?? err.error}');
      print('[API]    URL: ${err.requestOptions.uri}');
    }
    handler.next(err);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
