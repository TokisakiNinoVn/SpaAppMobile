import 'package:flutter/material.dart';

class Section extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;

  const Section({this.title, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              children: [
                if (icon != null) Icon(icon, size: 18, color: Colors.grey),
                if (icon != null) const SizedBox(width: 6),
                Text(title!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          if (title != null) const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}