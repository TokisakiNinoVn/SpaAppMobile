// file: lib/helper/format_helper.dart
import '../../../config/app_config.dart';

class FormatHelper {
  static String formatImageUrl(String url) {
    return '${AppConfig.apiUrlImage}$url';
  }

  static String formatDateTime(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  static String formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }


}