import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/constants.dart';

// Typed API exceptions
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException() : super('Network error. Check your connection.');
}

class AuthException extends ApiException {
  const AuthException() : super('Authentication failed. Please login again.', statusCode: 401);
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message) : super(statusCode: 404);
}

// Auth interceptor
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }
}

// Error interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: const NetworkException(),
        type: err.type,
      ));
      return;
    }

    if (response != null) {
      switch (response.statusCode) {
        case 401:
          handler.reject(DioException(
            requestOptions: err.requestOptions,
            error: const AuthException(),
            response: response,
          ));
          return;
        case 404:
          final message = _extractMessage(response.data) ?? 'Resource not found';
          handler.reject(DioException(
            requestOptions: err.requestOptions,
            error: NotFoundException(message),
            response: response,
          ));
          return;
        default:
          final message = _extractMessage(response.data) ?? err.message ?? 'Unknown error';
          handler.reject(DioException(
            requestOptions: err.requestOptions,
            error: ApiException(message, statusCode: response.statusCode),
            response: response,
          ));
          return;
      }
    }

    handler.next(err);
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['detail']?.toString() ??
          data['message']?.toString() ??
          data['error']?.toString();
    }
    return null;
  }
}

// Retry interceptor
// Retry interceptor removed — retrying on connection errors causes duplicate
// CORS failures in the browser console and confuses error reporting.
// Errors are surfaced immediately through the error handlers instead.

Dio _createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    _AuthInterceptor(),
    _ErrorInterceptor(),
  ]);

  return dio;
}

final apiClientProvider = Provider<Dio>((ref) {
  return _createDio();
});
