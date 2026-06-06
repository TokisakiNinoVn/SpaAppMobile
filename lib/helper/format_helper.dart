// file: lib/helper/format_helper.dart
import 'package:intl/intl.dart';

import '../config/app_config.dart';

class FormatHelper {
  static String formatNetworkImageUrl(String url) {
    // Nếu đã là full URL thì trả về luôn
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    return '${AppConfig.apiUrlImage}$url';
  }

  static String formatImageUrl(String url) {
    // print("URL origin image: $url");
    return '$url';
  }

  static String formatNameTechnician(String name) {
    return name.split('-').first.trim();
  }

  static String formatDateTime(String dateString) {
    final date = DateTime.parse(dateString);

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
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

  static String formatDateTimeTypeDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatPhoneInternational(String phone) {
    // Xóa khoảng trắng, dấu -, dấu .
    String cleaned = phone.replaceAll(RegExp(r'[\s\-.]'), '');

    if (cleaned.startsWith('+84')) {
      return cleaned;
    }

    if (cleaned.startsWith('84')) {
      return '+$cleaned';
    }

    if (cleaned.startsWith('0')) {
      return '+84${cleaned.substring(1)}';
    }

    return cleaned;
  }

  static int safeInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.round();

    if (value is num) return value.round();

    return int.tryParse(value.toString()) ?? 0;
  }
}