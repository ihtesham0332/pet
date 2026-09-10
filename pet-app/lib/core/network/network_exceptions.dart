import 'package:dio/dio.dart';

/// ── Custom Network Exception ──────────────────────────────────────
/// Wraps all DioExceptions into user-friendly messages so the UI
/// never shows raw technical errors like "DioException [connection timeout]".
class NetworkException implements Exception {
  final String message;
  final String? technicalDetails;
  final NetworkErrorType type;
  final int? statusCode;

  const NetworkException({
    required this.message,
    required this.type,
    this.technicalDetails,
    this.statusCode,
  });

  /// Factory: converts a raw [DioException] into a clean [NetworkException].
  factory NetworkException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          message: 'Unable to reach the server. Please check that the backend is running and your device is on the same network.',
          type: NetworkErrorType.connectionTimeout,
          technicalDetails: 'Connection timeout: ${error.requestOptions.uri}',
        );

      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Request took too long to send. Please check your internet connection.',
          type: NetworkErrorType.sendTimeout,
          technicalDetails: 'Send timeout: ${error.requestOptions.uri}',
        );

      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Server took too long to respond. Please try again.',
          type: NetworkErrorType.receiveTimeout,
          technicalDetails: 'Receive timeout: ${error.requestOptions.uri}',
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Cannot connect to server. Please check your internet connection and try again.',
          type: NetworkErrorType.noConnection,
          technicalDetails: 'Connection error: ${error.message}',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        return NetworkException(
          message: _messageForStatusCode(statusCode),
          type: NetworkErrorType.serverError,
          statusCode: statusCode,
          technicalDetails: 'HTTP $statusCode: ${error.response?.data}',
        );

      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'Request was cancelled.',
          type: NetworkErrorType.cancelled,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Security certificate error. Please try again later.',
          type: NetworkErrorType.other,
          technicalDetails: 'Bad certificate: ${error.message}',
        );

      case DioExceptionType.unknown:
      default:
        // Check if it's a SocketException (common cause of the user's error)
        final errorMsg = error.error?.toString() ?? error.message ?? '';
        if (errorMsg.contains('SocketException') ||
            errorMsg.contains('Connection timed out') ||
            errorMsg.contains('Connection refused')) {
          return NetworkException(
            message: 'Cannot connect to server. Please ensure the backend server is running.',
            type: NetworkErrorType.noConnection,
            technicalDetails: errorMsg,
          );
        }
        return NetworkException(
          message: 'An unexpected network error occurred. Please try again.',
          type: NetworkErrorType.other,
          technicalDetails: error.message,
        );
    }
  }

  static String _messageForStatusCode(int code) {
    switch (code) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This action conflicts with existing data. Please refresh and try again.';
      case 422:
        return 'Invalid data submitted. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Server is temporarily unavailable. Please try again in a moment.';
      case 503:
        return 'Service is under maintenance. Please try again later.';
      default:
        if (code >= 500) return 'Server error. Please try again later.';
        return 'Request failed. Please try again.';
    }
  }

  /// Whether this error is retryable (timeouts, connection errors).
  bool get isRetryable =>
      type == NetworkErrorType.connectionTimeout ||
      type == NetworkErrorType.sendTimeout ||
      type == NetworkErrorType.receiveTimeout ||
      type == NetworkErrorType.noConnection;

  @override
  String toString() => 'NetworkException: $message';
}

/// Types of network errors for programmatic handling.
enum NetworkErrorType {
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  noConnection,
  serverError,
  cancelled,
  other,
}
