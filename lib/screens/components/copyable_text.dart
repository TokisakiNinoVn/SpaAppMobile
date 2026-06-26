import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

class CopyableText extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? successMessage;
  final TextStyle? textStyle;

  const CopyableText({
    super.key,
    required this.text,
    this.icon,
    this.successMessage,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
        ],

        Flexible(
          child: Text(
            text,
            style:
            textStyle ??
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
          ),
        ),

        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: text),
            );

            if (context.mounted) {
              SnackBarHelper.showSuccess(
                context,
                successMessage ?? "Đã sao chép",
              );
            }
          },
        ),
      ],
    );
  }
}