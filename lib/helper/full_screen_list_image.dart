import 'dart:io';
import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/utils/image_download_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;
  final String Function(String) formatImageUrl;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.formatImageUrl,
  });

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await ImageDownloadUtil.initializeNotifications();
  }

  Future<void> _downloadImage(String imageUrl) async {
    setState(() => _isDownloading = true);
    final linkImageUrl = FormatHelper.formatNetworkImageUrl(imageUrl);
    await ImageDownloadUtil.downloadImage(
      imageUrl: linkImageUrl,
      // imageUrl: imageUrl,
      context: context,
      onComplete: (_) {
        setState(() => _isDownloading = false);
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final imageUrl = FormatHelper.formatNetworkImageUrl(widget.images[index]['url']);
              return InteractiveViewer(
                maxScale: 4.0,
                minScale: 1.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: ColorConfig.primary,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: ColorConfig.primary,
              onPressed: _isDownloading
                  ? null
                  : () => _downloadImage(widget.formatImageUrl(widget.images[_currentIndex]['url'])),
              child: _isDownloading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(
                Icons.download,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.images.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}