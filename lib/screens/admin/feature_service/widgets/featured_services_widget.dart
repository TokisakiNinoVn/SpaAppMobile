import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';

class FeaturedServicesWidget extends StatelessWidget {
  // final bool isDark;
  final String massageImage;
  final String skincareImage;
  final String skincareImage2;

  const FeaturedServicesWidget({
    super.key,
    // required this.isDark,
    required this.massageImage,
    required this.skincareImage,
    required this.skincareImage2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildImageServiceCard(
            context: context,
            title: 'Đặt Kỹ thuật viên tại nhà',
            description:
            'Dịch vụ massage & chăm sóc sức khỏe tại nhà theo yêu cầu',
            router: '/home-customer/list-technician',
            imageUrl: massageImage,
            tag: 'Phổ biến',
            tagColor: ColorConfig.primary,
          ),
          const SizedBox(height: 16),
          _buildImageServiceCard(
            context: context,
            title: 'Đặt lịch trước',
            description: 'Chọn kỹ thuật viên và thời gian phù hợp với bạn',
            router: CustomerRouterConfig.books,
            imageUrl: skincareImage,
            tag: 'Mới',
            tagColor: ColorConfig.primary,
          ),
          const SizedBox(height: 16),
          _buildImageServiceCard(
            context: context,
            title: 'Ghép kỹ thuật viên tự động',
            description: 'Hệ thống sẽ chọn kỹ thuật viên phù hợp cho bạn',
            router: CustomerRouterConfig.automaticMatching,
            imageUrl: skincareImage2,
            tag: 'Mới',
            tagColor: ColorConfig.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildImageServiceCard({
    required BuildContext context,
    required String title,
    required String description,
    required String imageUrl,
    required String router,
    required String tag,
    required Color tagColor,
  }) {
    return InkWell(
      onTap: () {
        if (router.isNotEmpty) {
          context.go(router);
        }
      },

      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(.3),
                      Colors.black.withOpacity(1),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: tagColor.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}