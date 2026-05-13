import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {

  static const String urlImage1DiscountHome = "https://i.pinimg.com/1200x/57/15/12/57151294cfea55e5190910a4e3ab1d48.jpg";
  static const String urlImage2DiscountHome = "https://i.pinimg.com/736x/46/07/5f/46075f13a2009a747fdfb1987a1f75d9.jpg";

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
