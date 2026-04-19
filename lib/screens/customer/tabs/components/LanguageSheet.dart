import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';

import '../../../../storages/language_storage.dart';
import '../../../../models/Lang.dart';

class LanguageSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const LanguageSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0D8CF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chọn ngôn ngữ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ColorConfig.textBlack,
            ),
          ),
          const SizedBox(height: 20),
          ...kLanguages.map((lang) {
            final isSelected = lang.code == selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () async {
                  await LanguageStorage.saveLanguage(lang.code);
                  onSelect(lang.code);
                  Navigator.of(context).pop();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(0xFFBAB5AD).withOpacity(0.08)
                        : const Color(0xFFF9F5F0),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: isSelected ? ColorConfig.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          lang.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Color(0xFF8B7355)
                                : const Color(0xFF3D2C1E),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ColorConfig.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}