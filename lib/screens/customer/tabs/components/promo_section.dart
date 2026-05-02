import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';

class PromoSection extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onViewAll;

  const PromoSection({
    super.key,
    required this.children,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConfig.primaryBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Ưu đãi hấp dẫn",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Row(
            children: const [
              Text(
                "Xem tất cả",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.green),
            ],
          ),
        )
      ],
    );
  }
}
