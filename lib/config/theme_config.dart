import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  static TextStyle appTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    if (Platform.isIOS) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: '.SF Pro Text',
        color: color,
      );
    } else {
      return GoogleFonts.roboto(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }
}
