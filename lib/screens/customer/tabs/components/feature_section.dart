import 'package:flutter/material.dart';

import 'feature_item.dart';

class FeatureSection extends StatelessWidget {
  const FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: FeatureItem(
                  icon: Icons.person,
                  title: "KTV chuyên nghiệp",
                  subtitle: "Kinh nghiệm lâu năm",
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: FeatureItem(
                  icon: Icons.spa,
                  title: "Sản phẩm cao cấp",
                  subtitle: "Nguồn gốc rõ ràng, an toàn",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: FeatureItem(
                  icon: Icons.lock,
                  title: "An toàn & Bảo mật",
                  subtitle: "Thông tin khách hàng được bảo mật",
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: FeatureItem(
                  icon: Icons.calendar_today,
                  title: "Đặt lịch dễ dàng",
                  subtitle: "Nhanh chóng, tiện lợi mọi lúc mọi nơi",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
