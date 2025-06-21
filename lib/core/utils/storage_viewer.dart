import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Utility class to view SharedPreferences data
class StorageViewer {
  static Future<void> printAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    print('=== SharedPreferences Data ===');
    print('Total keys: ${keys.length}');
    print('');
    
    for (final key in keys) {
      final value = prefs.get(key);
      print('Key: $key');
      print('Type: ${value.runtimeType}');
      
      if (value is String) {
        try {
          // Try to parse as JSON
          final jsonData = jsonDecode(value);
          print('Value (JSON):');
          print(const JsonEncoder.withIndent('  ').convert(jsonData));
        } catch (e) {
          print('Value (String): $value');
        }
      } else {
        print('Value: $value');
      }
      print('---');
    }
  }

  static Future<void> printSpecificKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(key);
    
    if (value == null) {
      print('Key "$key" not found');
      return;
    }
    
    print('=== Key: $key ===');
    print('Type: ${value.runtimeType}');
    
    if (value is String) {
      try {
        final jsonData = jsonDecode(value);
        print('Value (JSON):');
        print(const JsonEncoder.withIndent('  ').convert(jsonData));
      } catch (e) {
        print('Value (String): $value');
      }
    } else {
      print('Value: $value');
    }
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('All SharedPreferences data cleared');
  }

  static Future<void> listKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    print('=== Available Keys ===');
    for (final key in keys) {
      print('- $key');
    }
  }
} 