import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// A utility class for centralized logging throughout the app.
/// Supports both console and file logging for debugging purposes.
class AppLogger {
  static final _logger = Logger('CashSify');
  static File? _logFile;
  static const String _logFileName = 'cashsify_logs.txt';
  static const int _maxLogFileSize = 10 * 1024 * 1024; // 5MB
  static const int _maxLogEntries = 1000; // Keep last 1000 entries

  /// Initialize the logger with file logging support
  static Future<void> init() async {
    try {
      await _initializeLogFile();
      
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        _logToConsole(record);
        _logToFile(record);
      });
      
      info('Logger initialized successfully');
    } catch (e, stackTrace) {
      // Fallback to console only if file logging fails
      print('Failed to initialize file logging: $e');
      _initializeConsoleOnly();
    }
  }

  /// Initialize log file in app's internal storage
  static Future<void> _initializeLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFilePath = '${directory.path}/$_logFileName';
      _logFile = File(logFilePath);
      
      // Create file if it doesn't exist
      if (!await _logFile!.exists()) {
        await _logFile!.create();
        await _logFile!.writeAsString('=== CashSify App Logs ===\n');
      }
      
      // Check file size and rotate if necessary
      await _checkAndRotateLogFile();
    } catch (e) {
      print('Error initializing log file: $e');
      rethrow;
    }
  }

  /// Check log file size and rotate if necessary
  static Future<void> _checkAndRotateLogFile() async {
    if (_logFile == null) return;
    
    try {
      final fileSize = await _logFile!.length();
      if (fileSize > _maxLogFileSize) {
        await _rotateLogFile();
      }
    } catch (e) {
      print('Error checking log file size: $e');
    }
  }

  /// Rotate log file by keeping only recent entries
  static Future<void> _rotateLogFile() async {
    if (_logFile == null) return;
    
    try {
      final lines = await _logFile!.readAsLines();
      if (lines.length > _maxLogEntries) {
        final recentLines = lines.length > _maxLogEntries
            ? lines.sublist(lines.length - _maxLogEntries)
            : lines;
        await _logFile!.writeAsString(
          '=== CashSify App Logs (Rotated) ===\n${recentLines.join('\n')}\n'
        );
      }
    } catch (e) {
      print('Error rotating log file: $e');
    }
  }

  /// Initialize console-only logging (fallback)
  static void _initializeConsoleOnly() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      _logToConsole(record);
    });
  }

  /// Log to console
  static void _logToConsole(LogRecord record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      // ignore: avoid_print
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('Stack trace: ${record.stackTrace}');
    }
  }

  /// Log to file
  static Future<void> _logToFile(LogRecord record) async {
    if (_logFile == null) return;
    
    try {
      final timestamp = record.time.toIso8601String();
      final level = record.level.name.padRight(5);
      final message = record.message;
      
      String logEntry = '[$timestamp] $level: $message';
      
      if (record.error != null) {
        logEntry += '\nError: ${record.error}';
      }
      
      if (record.stackTrace != null) {
        logEntry += '\nStack trace: ${record.stackTrace}';
      }
      
      logEntry += '\n';
      
      await _logFile!.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      print('Error writing to log file: $e');
    }
  }

  /// Get the log file path for debugging purposes
  static Future<String?> getLogFilePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/$_logFileName';
    } catch (e) {
      print('Error getting log file path: $e');
      return null;
    }
  }

  /// Get log file content for debugging purposes
  static Future<String?> getLogFileContent() async {
    if (_logFile == null) return null;
    
    try {
      if (await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
      return null;
    } catch (e) {
      print('Error reading log file: $e');
      return null;
    }
  }

  /// Clear log file
  static Future<void> clearLogs() async {
    if (_logFile == null) return;
    
    try {
      await _logFile!.writeAsString('=== CashSify App Logs (Cleared) ===\n');
      info('Logs cleared successfully');
    } catch (e) {
      print('Error clearing logs: $e');
    }
  }

  /// Log info message
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
    _logger.info(message, error, stackTrace);
  }

  /// Log warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('⚠️ WARNING: $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
    _logger.warning(message, error, stackTrace);
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ ERROR: $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
    _logger.severe(message, error, stackTrace);
  }

  /// Log debug message
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('🔍 DEBUG: $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
    _logger.fine(message, error, stackTrace);
  }

  /// Log user action for debugging
  static void userAction(String action, [Map<String, dynamic>? data]) {
    final message = 'USER_ACTION: $action${data != null ? ' | Data: $data' : ''}';
    info(message);
  }

  /// Log API call for debugging
  static void apiCall(String endpoint, [Map<String, dynamic>? requestData, dynamic responseData]) {
    final message = 'API_CALL: $endpoint${requestData != null ? ' | Request: $requestData' : ''}${responseData != null ? ' | Response: $responseData' : ''}';
    info(message);
  }

  /// Log performance metric
  static void performance(String operation, Duration duration) {
    final message = 'PERFORMANCE: $operation took ${duration.inMilliseconds}ms';
    info(message);
  }

  /// Log crash/exception for debugging
  static void crash(String context, dynamic error, StackTrace? stackTrace) {
    final message = 'CRASH: $context';
    error(message, error, stackTrace);
  }

  /// Log user session events
  static void userSession(String event, [Map<String, dynamic>? data]) {
    final message = 'SESSION: $event${data != null ? ' | Data: $data' : ''}';
    info(message);
  }

  /// Log navigation events
  static void navigation(String from, String to, [Map<String, dynamic>? params]) {
    final message = 'NAVIGATION: $from -> $to${params != null ? ' | Params: $params' : ''}';
    info(message);
  }

  /// Log network events
  static void network(String event, [String? url, int? statusCode, String? error]) {
    final message = 'NETWORK: $event${url != null ? ' | URL: $url' : ''}${statusCode != null ? ' | Status: $statusCode' : ''}${error != null ? ' | Error: $error' : ''}';
    info(message);
  }

  /// Log database operations
  static void database(String operation, String table, [Map<String, dynamic>? data, String? error]) {
    final message = 'DATABASE: $operation on $table${data != null ? ' | Data: $data' : ''}${error != null ? ' | Error: $error' : ''}';
    info(message);
  }

  /// Log authentication events
  static void auth(String event, [String? userId, String? error]) {
    final message = 'AUTH: $event${userId != null ? ' | User: $userId' : ''}${error != null ? ' | Error: $error' : ''}';
    info(message);
  }

  /// Log wallet/transaction events
  static void wallet(String event, [double? amount, String? currency, String? error]) {
    final message = 'WALLET: $event${amount != null ? ' | Amount: $amount $currency' : ''}${error != null ? ' | Error: $error' : ''}';
    info(message);
  }

  /// Log referral events
  static void referral(String event, [String? referralCode, String? error]) {
    final message = 'REFERRAL: $event${referralCode != null ? ' | Code: $referralCode' : ''}${error != null ? ' | Error: $error' : ''}';
    info(message);
  }

  /// Log ad-related events
  static void ads(String event, [String? adType, double? earnings, String? error]) {
    final message = 'ADS: $event${adType != null ? ' | Type: $adType' : ''}${earnings != null ? ' | Earnings: $earnings' : ''}${error != null ? ' | Error: $error' : ''}';
    info(message);
  }
} 