import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddressUtil {
  static Future<String> getFormatAddressProvince() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('address') ?? "";

    if (address.isEmpty) return "";
    final parts = address.split(',');
    String province = parts.isNotEmpty ? parts.last.trim() : "";
    print("Province: $province");

    return province;
  }

  static String formatAddressProvince(String address) {
    if (address.trim().isEmpty) return "";

    final parts = address.split(',');
    if (parts.isEmpty) return "";

    String province = parts.last.trim();
    province = province.replaceAll(RegExp(r'\s+'), ' ');

    return province;
  }


  static Future<String?> getAddressFromLatLng(double lat, double lng) async {
    print("✅ lat:$lat - long:$lng");
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'spa-app',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 👉 lấy địa chỉ full
        final displayName = data['display_name'];

        // 👉 hoặc custom lại cho đẹp hơn
        final address = data['address'];
        final road = address['road'] ?? '';
        final suburb = address['suburb'] ?? address['village'] ?? '';
        final city = address['city'] ?? address['state'] ?? '';

        return '$road, $suburb, $city';
      } else {
        debugPrint('Reverse geocoding failed');
        return null;
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return null;
    }
  }
}
