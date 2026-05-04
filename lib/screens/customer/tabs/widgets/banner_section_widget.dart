import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';

class BannerSectionWidget extends StatelessWidget {
  final bool isBannerLoading;
  final String? bannerError;
  final List<Map<String, dynamic>> bannerData;
  final int currentBannerIndex;
  final PageController bannerController;
  final Function(int) onBannerPageChanged;

  const BannerSectionWidget({
    super.key,
    required this.isBannerLoading,
    required this.bannerError,
    required this.bannerData,
    required this.currentBannerIndex,
    required this.bannerController,
    required this.onBannerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double borderImage = 10;
    if (isBannerLoading && bannerData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.grey[300],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFD4845A),
            ),
          ),
        ),
      );
    }

    if (bannerError != null || bannerData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.grey[200],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  bannerError ?? 'Không có banner',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PageView.builder(
                  controller: bannerController,
                  onPageChanged: (i) => onBannerPageChanged(i),
                  itemCount: bannerData.length,
                    itemBuilder: (_, i) {
                      final item = bannerData[i];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(borderImage),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(borderImage),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                /// IMAGE
                                Positioned.fill(
                                  child: CachedNetworkImage(
                                    imageUrl: item['image'],
                                    cacheKey: 'banner_${item['id'] ?? item['image']}',

                                    /// QUAN TRỌNG: dùng imageBuilder
                                    imageBuilder: (context, imageProvider) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(borderImage),
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },

                                    placeholder: (context, url) => Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(borderImage),
                                        color: Colors.grey[200],
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFD4845A),
                                        ),
                                      ),
                                    ),

                                    errorWidget: (context, url, error) => Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(borderImage),
                                        color: Colors.grey[300],
                                      ),
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    fadeInDuration: const Duration(milliseconds: 1000), // mượt hơn
                                  ),
                                ),


                                /// GRADIENT OVERLAY
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        stops: const [0.0, 0.4, 0.7, 1.0],
                                        colors: [
                                          ColorConfig.primary,
                                          ColorConfig.primary.withOpacity(0.9),
                                          ColorConfig.primary.withOpacity(0.4),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                /// CONTENT
                                Positioned(
                                  left: 20,
                                  top: 28,
                                  right: 20,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item['description'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          context.push(
                                            CustomerRouterConfig.listOrderNowTechnician,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: ColorConfig.textPrimary,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          'Đặt lịch ngay',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                ),
                if (bannerData.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        bannerData.length,
                            (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: currentBannerIndex == i ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: currentBannerIndex == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}