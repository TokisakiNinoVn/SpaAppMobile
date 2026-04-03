// lib/core/utils/logger.dart
import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';

import '../config/app_config.dart';

void appLog(String message, {Object? data}) {
  // Chỉ in log khi không phải môi trường production
  if (AppConfig.isProduction) return;

  // Lấy StackTrace để biết file + dòng đang gọi log
  final stackTrace = StackTrace.current.toString().split('\n')[1];

  // Parse lại cho đẹp
  final regex = RegExp(r'#1\s+(.+)\s+\((.+):(\d+):\d+\)');
  final match = regex.firstMatch(stackTrace);

  final callerInfo = match != null
      ? "${match.group(2)}:${match.group(3)}"
      : "unknown";

  final logMessage = "[$callerInfo] $message";

  if (data != null) {
    developer.log(logMessage, error: data);
  } else {
    debugPrint(logMessage);
  }
}
