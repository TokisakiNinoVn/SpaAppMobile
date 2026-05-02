import 'package:flutter/material.dart';

class InputBox extends StatelessWidget {
  final String? text;
  final bool isPlaceholder;
  final Widget? child;
  final bool isFocused;

  const InputBox({
    this.text,
    this.isPlaceholder = false,
    this.child,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: child ?? Text(text ?? '', style: TextStyle(color: isPlaceholder ? Colors.grey : Colors.black)),
          ),
        ],
      ),
    );
  }
}
