// lib/helpers/snackbar_helper.dart

import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';

class SnackBarHelper {
  static void showSuccess(
      BuildContext context,
      String message, {
        double radius = 16,
      }) =>
      _show(
        context,
        title: 'Thành công',
        message: message,
        icon: Icons.check_circle_rounded,
        color: ColorConfig.primary,
        radius: radius,
      );

  static void showError(
      BuildContext context,
      String message, {
        double radius = 16,
      }) =>
      _show(
        context,
        title: 'Đã xảy ra lỗi',
        message: message,
        icon: Icons.cancel_rounded,
        color: ColorConfig.textError,
        radius: radius,
      );

  static void showWarning(
      BuildContext context,
      String message, {
        double radius = 16,
      }) =>
      _show(
        context,
        title: 'Cảnh báo',
        message: message,
        icon: Icons.warning_amber_rounded,
        color: ColorConfig.textWarning,
        radius: radius,
      );

  static void _show(
      BuildContext context, {
        required String title,
        required String message,
        required IconData icon,
        required Color color,
        double radius = 16,
      }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          duration: const Duration(seconds: 3),

          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),

            child: Row(
              children: [
                _IconBox(icon: icon),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ThemeConfig.appTextStyle(
                          color: ColorConfig.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        message,
                        style: ThemeConfig.appTextStyle(
                          color: ColorConfig.white.withOpacity(0.95),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: messenger.hideCurrentSnackBar,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: ColorConfig.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: ColorConfig.white,
        size: 22,
      ),
    );
  }
}