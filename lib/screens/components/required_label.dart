import 'package:flutter/material.dart';

class RequiredLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  const RequiredLabel({
    super.key,
    required this.text,
    this.isRequired = true,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}