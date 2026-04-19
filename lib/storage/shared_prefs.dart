import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/storage/pref_type.dart';

class SharedPrefs {
  static Future<void> saveValue(PrefType type, String key, dynamic value) async {
    // appLog('Saving value: $value with type: ${value == null ? "null" : value.runtimeType} for key: $key');
    final prefs = await SharedPreferences.getInstance();

    switch (type) {
      case PrefType.string:
        if (value is Map || value is List) {
          await prefs.setString(key, jsonEncode(value));
        } else {
          await prefs.setString(key, value.toString());
        }
        break;

      case PrefType.int:
        await prefs.setInt(key, value as int);
        break;
      case PrefType.double:
        await prefs.setDouble(key, value as double);
        break;
      case PrefType.bool:
        await prefs.setBool(key, value as bool);
        break;
      case PrefType.stringList:
        await prefs.setStringList(key, value as List<String>);
        break;
    }
  }

  static Future<dynamic> getValue(PrefType type, String key) async {
    final prefs = await SharedPreferences.getInstance();

    switch (type) {
      case PrefType.string:
        return prefs.getString(key);
      case PrefType.int:
        return prefs.getInt(key);
      case PrefType.double:
        return prefs.getDouble(key);
      case PrefType.bool:
        return prefs.getBool(key);
      case PrefType.stringList:
        return prefs.getStringList(key);
    }
  }
}
