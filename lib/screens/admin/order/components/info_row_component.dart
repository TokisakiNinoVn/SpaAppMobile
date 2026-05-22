import 'package:flutter/material.dart';

class InfoRowComponent extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const InfoRowComponent(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: valueStyle ??
                  const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}