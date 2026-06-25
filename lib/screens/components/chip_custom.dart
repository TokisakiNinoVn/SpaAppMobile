import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? textColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const StatusChip({
    super.key,
    required this.label,
    this.textColor,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      padding ??
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: textColor ?? Colors.grey,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}