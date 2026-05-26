import 'package:flutter/material.dart';

class SectionComponent extends StatelessWidget {
  final Widget? widgetTitle;
  final String? stringTitle;
  final IconData? icon;
  final Widget child;

  const SectionComponent({
    super.key,
    this.widgetTitle,
    this.stringTitle,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = widgetTitle != null || stringTitle != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle)
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 8),
              ],

              Expanded(
                child: widgetTitle ??
                    Text(
                      stringTitle ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ],
          ),

        if (hasTitle)
          const SizedBox(height: 12),

        child,
      ],
    );
  }
}