import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/utils/image_download_util.dart';

class FullScreenSingleImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenSingleImageViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  State<FullScreenSingleImageViewer> createState() =>
      _FullScreenSingleImageViewerState();
}

class _FullScreenSingleImageViewerState
    extends State<FullScreenSingleImageViewer> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final linkImageUrl = widget.imageUrl;
      // appLog("Full URL image: $linkImageUrl");

      await ImageDownloadUtil.downloadImage(
        imageUrl: linkImageUrl,
        context: context,
        onComplete: (_) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.imageUrl;
    // appLog("Full URL image: $imageUrl");

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFD4A373),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          /// Nút đóng
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          /// Nút tải ảnh
          Positioned(
            bottom: 20,
            right: 20,
            child: SafeArea(
              child: FloatingActionButton(
                backgroundColor: ColorConfig.primary,
                onPressed: _isDownloading ? null : _downloadImage,
                child: _isDownloading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}