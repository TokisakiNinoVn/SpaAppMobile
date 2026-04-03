// file: lib/helper/format_helper.dart
// import '../../../config/app_config.dart';
import 'package:intl/intl.dart';
import 'dart:ffi';

class FormatHelper {
  // static String formatImageUrl(String url) {
  //   // print("URL origin image: $url");
  //   return '${AppConfig.apiUrlImage}$url';
  // }
  static String formatImageUrl(String url) {
    // print("URL origin image: $url");
    return '$url';
  }

  static String formatNameTechnician(String name) {
    return name.split('-').first.trim();
  }

  static String formatDateTime(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  static String formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  static DateTime parseDateTime(String dateString) {
    return DateTime.parse(dateString);
  }
  static String formatGender(String? gender) {
    if (gender == null) return "Không xác định";
    return gender.toLowerCase() == "male" ? "Nam" : "Nữ";
  }

  static String formatPrice(int? price) {
    if (price == null) return '0';
    return NumberFormat('#,###', 'vi_VN').format(price);
  }
}