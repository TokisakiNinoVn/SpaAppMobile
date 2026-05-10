import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';

class FeaturedServicesWidgetV2 extends StatelessWidget {
  final String title;
  final String description;
  final String tag;
  final String imageUrl;
  final String router;
  final int startPrice;

  const FeaturedServicesWidgetV2({
    super.key,
    required this.title,
    required this.description,
    required this.tag,
    required this.imageUrl,
    required this.router,
    required this.startPrice
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildImageServiceCard(
            context: context,
            title: title,
            description: description,
            router: router,
            imageUrl: FormatHelper.formatNetworkImageUrl(imageUrl),
            tag: tag,
            startPrice: FormatHelper.formatPrice(startPrice),
            tagColor: ColorConfig.primary,
          ),
          const SizedBox(height: 1),
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
    required String startPrice,
    required Color tagColor,
  }) {
    return InkWell(
      onTap: () {
        if (router.isNotEmpty) {
          context.push(router);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                /// TAG
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            /// CONTENT
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// DESCRIPTION
                  SizedBox(
                    height: 9 * 1.4 * 3,
                    child: Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ),


                  const SizedBox(height: 12),

                  /// PRICE + BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Từ ${startPrice}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                      ),

                      Container(
                        width: 36,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.black54,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}