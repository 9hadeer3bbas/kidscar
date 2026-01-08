import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Helper class for Firestore operations with retry logic and network checks
class FirestoreRetryHelper {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connectivity
  static Future<bool> hasConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
      
      if (kDebugMode) {
        debugPrint('🌐 Connectivity check: $result -> $hasConnection');
      }
      
      return hasConnection;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking connectivity: $e');
      }
      // Assume connectivity if check fails (optimistic)
      return true;
    }
  }

  /// Execute a Firestore operation with retry logic
  /// 
  /// [operation] - The Firestore operation to execute
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry in seconds (default: 1)
  /// [maxDelay] - Maximum delay between retries in seconds (default: 10)
  /// [exponentialBackoff] - Whether to use exponential backoff (default: true)
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    int initialDelay = 1,
    int maxDelay = 10,
    bool exponentialBackoff = true,
    String? operationName,
  }) async {
    int attempt = 0;
    int delay = initialDelay;
    Exception? lastException;

    while (attempt <= maxRetries) {
      try {
        // Check connectivity before attempting operation
        if (attempt > 0) {
          final hasConnection = await hasConnectivity();
          if (!hasConnection) {
            throw Exception(
              'No internet connection. Please check your network settings.',
            );
          }
        }

        if (kDebugMode && operationName != null) {
          debugPrint(
            '🔄 Firestore operation "$operationName" attempt ${attempt + 1}/${maxRetries + 1}',
          );
        }

        final result = await operation();
        
        if (kDebugMode && operationName != null) {
          debugPrint('✅ Firestore operation "$operationName" succeeded');
        }

        return result;
      } on FirebaseException catch (e) {
        lastException = e;
        
        if (kDebugMode) {
          debugPrint(
            '❌ Firestore error (attempt ${attempt + 1}/${maxRetries + 1}): ${e.code} - ${e.message}',
          );
        }

        // Don't retry on certain errors
        if (_isNonRetryableError(e.code)) {
          if (kDebugMode) {
            debugPrint('❌ Non-retryable error: ${e.code}');
          }
          rethrow;
        }

        // If this was the last attempt, throw the exception
        if (attempt >= maxRetries) {
          if (kDebugMode) {
            debugPrint('❌ Max retries reached for "$operationName"');
          }
          rethrow;
        }

        // Wait before retrying
        if (exponentialBackoff) {
          delay = min(delay * 2, maxDelay);
        }
        
        if (kDebugMode) {
          debugPrint('⏳ Retrying in $delay seconds...');
        }
        
        await Future.delayed(Duration(seconds: delay));
        attempt++;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (kDebugMode) {
          debugPrint(
            '❌ Error (attempt ${attempt + 1}/${maxRetries + 1}): $e',
          );
        }

        // If this was the last attempt, throw the exception
        if (attempt >= maxRetries) {
          if (kDebugMode) {
            debugPrint('❌ Max retries reached for "$operationName"');
          }
          if (e is Exception) {
            rethrow;
          }
          throw Exception(e.toString());
        }

        // Wait before retrying
        if (exponentialBackoff) {
          delay = min(delay * 2, maxDelay);
        }
        
        if (kDebugMode) {
          debugPrint('⏳ Retrying in $delay seconds...');
        }
        
        await Future.delayed(Duration(seconds: delay));
        attempt++;
      }
    }

    // This should never be reached, but just in case
    throw lastException ?? Exception('Unknown error occurred');
  }

  /// Check if a Firestore error code is non-retryable
  static bool _isNonRetryableError(String code) {
    // These errors should not be retried
    const nonRetryableCodes = [
      'permission-denied',
      'unauthenticated',
      'invalid-argument',
      'not-found',
      'already-exists',
      'failed-precondition',
      'aborted',
      'out-of-range',
      'unimplemented',
      'internal',
      'data-loss',
    ];
    return nonRetryableCodes.contains(code);
  }

  /// Get a user-friendly error message from a Firestore exception
  static String getUserFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
          return 'Firestore service is temporarily unavailable. Please check your internet connection and try again.';
        case 'deadline-exceeded':
          return 'The operation took too long. Please check your internet connection and try again.';
        case 'resource-exhausted':
          return 'Too many requests. Please wait a moment and try again.';
        case 'permission-denied':
          return 'You do not have permission to perform this operation.';
        case 'unauthenticated':
          return 'You are not authenticated. Please sign in and try again.';
        case 'failed-precondition':
          return 'The operation failed due to a precondition. Please try again.';
        default:
          return 'An error occurred: ${error.message ?? error.code}';
      }
    } else if (error is Exception) {
      final message = error.toString();
      if (message.contains('No internet connection') ||
          message.contains('Unable to resolve host') ||
          message.contains('failed to connect')) {
        return 'No internet connection. Please check your network settings and try again.';
      }
      return message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

