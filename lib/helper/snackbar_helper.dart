// lib/helpers/snackbar_helper.dart
import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      backgroundColor: ColorConfig.primary,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      backgroundColor: ColorConfig.textError,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      backgroundColor: ColorConfig.textWarning,
    );
  }

  static void _showSnackbar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: ThemeConfig.appTextStyle(color: ColorConfig.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
      ),
    );
  }
}
