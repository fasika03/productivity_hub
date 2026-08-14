import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple JSON-backed persistence wrapper around SharedPreferences.
class Storage {
  static Future<dynamic> loadRaw(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> loadList(String key) async {
    final data = await loadRaw(key);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> loadMap(String key) async {
    final data = await loadRaw(key);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  static Future<void> save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }
}

String generateId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rand = (now % 100000).toString();
  return '$now$rand';
}
