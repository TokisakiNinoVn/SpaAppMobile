// widgets/empty_refresh_widget.dart

import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';

class EmptyRefreshWidget extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final String title;
  final String? subTitle;
  final IconData icon;
  final String buttonText;
  final double heightFactor;

  const EmptyRefreshWidget({
    super.key,
    required this.onRefresh,
    this.title = "Không có dữ liệu",
    this.subTitle,
    this.icon = Icons.inbox_rounded,
    this.buttonText = "Làm mới",
    this.heightFactor = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      backgroundColor: ColorConfig.primary,
      color: ColorConfig.white,
      onRefresh: onRefresh,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
            MediaQuery.of(context).size.height *
                heightFactor,

            child: Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [
                  Icon(
                    icon,
                    size: 70,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    title,
                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if(subTitle != null) ...[
                    Text(
                      subTitle!,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 14,
                        // fontWeight: FontWeight.w500,
                        color: Color(0xFF555555),
                      ),
                    ),

                    const SizedBox(height: 14),
                  ],


                  ElevatedButton.icon(
                    onPressed: onRefresh,

                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),

                    label: Text(buttonText),

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      ColorConfig.primary,

                      foregroundColor:
                      Colors.white,

                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}