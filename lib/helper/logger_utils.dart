// lib/core/utils/logger.dart
import 'dart:convert';
import 'dart:developer' as developer;

void appLog(String message, {Object? data}) {
  // Lấy StackTrace để biết file + dòng đang gọi log
  final stackTraceLines = StackTrace.current.toString().split('\n');
  final callerLine =
  stackTraceLines.length > 1 ? stackTraceLines[1] : '';

  final regex = RegExp(r'#1\s+.+\s+\((.+):(\d+):\d+\)');
  final match = regex.firstMatch(callerLine);

  final callerInfo = match != null
      ? '${match.group(1)}:${match.group(2)}'
      : 'unknown';

  String dataString = '';

  if (data != null) {
    try {
      // Pretty JSON – KHÔNG bị ...
      dataString = '\nDATA:\n${const JsonEncoder.withIndent('  ').convert(data)}';
    } catch (_) {
      // Fallback nếu object không encode được
      dataString = '\nDATA:\n${data.toString()}';
    }
  }

  final fullMessage = '''
[$callerInfo] $message$dataString
''';

  developer.log(
    fullMessage,
    name: 'APP_LOG',
  );
}
