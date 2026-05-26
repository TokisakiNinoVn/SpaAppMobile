import 'package:flutter/material.dart';

class RequiredLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const RequiredLabel({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.black,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}