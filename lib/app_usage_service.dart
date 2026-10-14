import 'dart:io';
import 'package:flutter/services.dart';

class AppUsageService {
  static const MethodChannel _channel = MethodChannel('productivity_hub/usage');

  static Future<bool> hasUsagePermission() async {
    if (!Platform.isAndroid) return false;

    return await _channel.invokeMethod<bool>(
          'hasUsagePermission',
        ) ??
        false;
  }

  static Future<void> openUsageSettings() async {
    if (!Platform.isAndroid) return;

    await _channel.invokeMethod('openUsageSettings');
  }

  static Future<List<Map<String, dynamic>>> getUsageStats() async {
    if (!Platform.isAndroid) return [];

    final List<dynamic>? result =
        await _channel.invokeMethod<List<dynamic>>('getUsageStats');

    if (result == null) return [];

    return result
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }
}
