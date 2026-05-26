import 'package:flutter/material.dart';

class InputBoxComponent extends StatelessWidget {
  final String? text;
  final bool isPlaceholder;
  final Widget? child;
  final bool isFocused;

  const InputBoxComponent({
    this.text,
    this.isPlaceholder = false,
    this.child,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: child ??
                Text(
                  text ?? '',
                  style: TextStyle(
                    color: isPlaceholder ? Colors.grey : Colors.black,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}