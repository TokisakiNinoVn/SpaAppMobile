import 'package:flutter/material.dart';

class MenuEntry {
  final IconData icon;
  final String label;
  final String route;
  final String type;

  const MenuEntry({
    required this.icon,
    required this.label,
    required this.route,
    this.type = 'screen',
  });
}