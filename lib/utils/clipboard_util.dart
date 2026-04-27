import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';

import '../helper/snackbar_helper.dart';

class ClipboardUtil {
  static void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    SnackBarHelper.showSuccess(context, "Đã sao chép: $text");
  }
}