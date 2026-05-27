// lib/helpers/snackbar_helper.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';

class SnackBarHelper {
  static OverlayEntry? _currentOverlay;
  static Timer? _timer;

  static void showSuccess(
      BuildContext context,
      String message, {
        double radius = 16,
      }) {
    _show(
      context,
      title: 'Thành công',
      message: message,
      icon: Icons.check_circle_rounded,
      color: ColorConfig.primary,
      radius: radius,
    );
  }

  static void showError(
      BuildContext context,
      String message, {
        double radius = 16,
      }) {
    _show(
      context,
      title: 'Đã xảy ra lỗi',
      message: message,
      icon: Icons.cancel_rounded,
      color: ColorConfig.textError,
      radius: radius,
    );
  }

  static void showWarning(
      BuildContext context,
      String message, {
        double radius = 16,
      }) {
    _show(
      context,
      title: 'Cảnh báo',
      message: message,
      icon: Icons.warning_amber_rounded,
      color: ColorConfig.textWarning,
      radius: radius,
    );
  }

  static void hide() {
    _timer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  static void _show(
      BuildContext context, {
        required String title,
        required String message,
        required IconData icon,
        required Color color,
        double radius = 16,
      }) {
    hide();

    final overlay = Overlay.of(
      context,
      rootOverlay: true,
    );

    _currentOverlay = OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);

        final keyboardHeight = mediaQuery.viewInsets.bottom;
        final bottomSafe = mediaQuery.padding.bottom;

        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  bottom: keyboardHeight > 0
                      ? keyboardHeight + 16
                      : bottomSafe + 16,
                  left: 18,
                  right: 18,
                  child: _AnimatedSnackBar(
                    title: title,
                    message: message,
                    icon: icon,
                    color: color,
                    radius: radius,
                    onClose: hide,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_currentOverlay!);

    _timer = Timer(const Duration(seconds: 3), hide);
  }
}

class _AnimatedSnackBar extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final double radius;
  final VoidCallback onClose;

  const _AnimatedSnackBar({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.radius,
    required this.onClose,
  });

  @override
  State<_AnimatedSnackBar> createState() => _AnimatedSnackBarState();
}

class _AnimatedSnackBarState extends State<_AnimatedSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _IconBox(icon: widget.icon),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: ThemeConfig.appTextStyle(
                          color: ColorConfig.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        widget.message,
                        style: ThemeConfig.appTextStyle(
                          color: ColorConfig.white.withOpacity(0.96),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: widget.onClose,
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
      width: 32,
      height: 32,
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