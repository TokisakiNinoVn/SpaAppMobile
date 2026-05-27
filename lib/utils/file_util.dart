// lib/utils/file_util.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:extended_image_library/extended_image_library.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spa_app/helper/logger_utils.dart';

import 'crop_editor_helper.dart';
import '../config/color_config.dart';

class FileUtils {
  Future<File?> cropImage(
      BuildContext context,
      File imageFile,
      double ratioX,
      double ratioY,
      ) async {
    final completer = Completer<File?>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CropScreen(
          imageFile: imageFile,
          ratioX: ratioX,
          ratioY: ratioY,
          completer: completer,
        ),
        fullscreenDialog: true,
      ),
    );

    return completer.future;
  }
}

class _CropScreen extends StatefulWidget {
  final File imageFile;
  final double ratioX;
  final double ratioY;
  final Completer<File?> completer;

  const _CropScreen({
    required this.imageFile,
    required this.ratioX,
    required this.ratioY,
    required this.completer,
  });

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final GlobalKey<ExtendedImageEditorState> editorKey =
  GlobalKey<ExtendedImageEditorState>();

  bool _isCropping = false;
  Future<void> _crop() async {
    try {
      setState(() => _isCropping = true);

      final state = editorKey.currentState;
      if (state == null) return;

      final Uint8List? data = await cropImageDataWithDartLibrary(state: state);

      if (data == null) throw Exception('Crop failed');

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(data);

      if (!widget.completer.isCompleted) {
        widget.completer.complete(file);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Crop error: $e');
      if (!widget.completer.isCompleted) {
        widget.completer.complete(null);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isCropping = false);
      }
    }
  }

  void _rotate() {
    editorKey.currentState?.rotate(
      degree: 90,
    );
  }

  void _cancel() {
    if (!widget.completer.isCompleted) {
      widget.completer.complete(null);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = widget.ratioX / widget.ratioY;

    return Scaffold(
      backgroundColor: ColorConfig.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _cancel,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Cắt ảnh',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _isCropping
                            ? null
                            : () async {
                          appLog("_isCropping: $_isCropping - Bắt đầu crop");
                          await _crop();
                        },

                        child: const Text(
                          'Xong',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ExtendedImage.file(
                    widget.imageFile,
                    fit: BoxFit.contain,
                    mode: ExtendedImageMode.editor,
                    extendedImageEditorKey: editorKey,
                    cacheRawData: true,
                    clearMemoryCacheWhenDispose: true,

                    initEditorConfigHandler: (_) {
                      return EditorConfig(
                        maxScale: 8.0,
                        cropAspectRatio: aspectRatio,

                        hitTestSize: 20,

                        cropRectPadding: const EdgeInsets.all(24),

                        cornerSize: const Size(28, 5),

                        lineColor: Colors.white,

                        editorMaskColorHandler: (context, pointerDown) {
                          return Colors.black.withOpacity(0.7);
                        },
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    32,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBottomButton(
                        icon: Icons.rotate_right,
                        label: 'Xoay',
                        onTap: _rotate,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_isCropping)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// // lib/utils/file_util.dart
//
// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:crop_your_image/crop_your_image.dart';
// import 'package:path_provider/path_provider.dart';
//
// import '../config/color_config.dart';
//
// class FileUtils {
//   /// Cắt ảnh với tỷ lệ khung hình cho trước.
//   /// Sử dụng package crop_your_image để hiển thị màn hình cắt tương tác.
//   /// Trả về File đã cắt hoặc null nếu người dùng hủy.
//   Future<File?> cropImage(
//       BuildContext context,
//       File imageFile,
//       double ratioX,
//       double ratioY,
//       ) async {
//     // Đọc file ảnh thành Uint8List vì Crop widget yêu cầu dạng này
//     final Uint8List imageBytes = await imageFile.readAsBytes();
//     final completer = Completer<File?>();
//
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => _CropScreen(
//           imageBytes: imageBytes,
//           ratioX: ratioX,
//           ratioY: ratioY,
//           completer: completer,
//         ),
//         fullscreenDialog: true,
//       ),
//     );
//
//     return completer.future;
//   }
// }
//
// /// Màn hình cắt ảnh sử dụng crop_your_image.
// class _CropScreen extends StatefulWidget {
//   final Uint8List imageBytes;
//   final double ratioX;
//   final double ratioY;
//   final Completer<File?> completer;
//
//   const _CropScreen({
//     required this.imageBytes,
//     required this.ratioX,
//     required this.ratioY,
//     required this.completer,
//   });
//
//   @override
//   State<_CropScreen> createState() => _CropScreenState();
// }
//
// class _CropScreenState extends State<_CropScreen> {
//   final CropController _controller = CropController();
//   bool _isCropping = false;
//
//   // CropController không có dispose, nên không cần gọi
//
//   Future<void> _crop() async {
//     setState(() => _isCropping = true);
//
//     _controller.crop();
//   }
//
//   void _cancel() {
//     if (!widget.completer.isCompleted) {
//       widget.completer.complete(null);
//     }
//     Navigator.of(context).pop();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final aspectRatio = widget.ratioX / widget.ratioY;
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text('Cắt ảnh'),
//         backgroundColor: ColorConfig.primary,
//         foregroundColor: Colors.white,
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: _cancel,
//         ),
//         actions: [
//           TextButton(
//             onPressed: _isCropping ? null : _crop,
//             child: const Text(
//               'Xong',
//               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Crop(
//             image: widget.imageBytes,
//
//             controller: _controller,
//
//             aspectRatio: aspectRatio,
//
//             radius: 12,
//
//             baseColor: Colors.black,
//
//             maskColor: Colors.black.withOpacity(0.7),
//
//             interactive: true,
//
//             fixCropRect: true,
//
//             withCircleUi: false,
//
//             onStatusChanged: (status) {},
//             onCropped: (CropResult result) async {
//               try {
//                 if (result is! CropSuccess) {
//                   if (!widget.completer.isCompleted) {
//                     widget.completer.complete(null);
//                   }
//
//                   if (mounted) {
//                     Navigator.of(context).pop();
//                   }
//
//                   return;
//                 }
//
//                 final Uint8List croppedBytes =
//                     result.croppedImage;
//
//                 final tempDir =
//                 await getTemporaryDirectory();
//
//                 final timestamp =
//                     DateTime.now().millisecondsSinceEpoch;
//
//                 final croppedFile = File(
//                   '${tempDir.path}/cropped_$timestamp.jpg',
//                 );
//
//                 await croppedFile.writeAsBytes(
//                   croppedBytes,
//                 );
//
//                 if (!widget.completer.isCompleted) {
//                   widget.completer.complete(croppedFile);
//                 }
//
//                 if (mounted) {
//                   Navigator.of(context).pop();
//                 }
//               } catch (e) {
//                 debugPrint('Crop error: $e');
//
//                 if (!widget.completer.isCompleted) {
//                   widget.completer.complete(null);
//                 }
//
//                 if (mounted) {
//                   Navigator.of(context).pop();
//                 }
//               } finally {
//                 if (mounted) {
//                   setState(() => _isCropping = false);
//                 }
//               }
//             },
//           ),
//           if (_isCropping)
//             Container(
//               color: Colors.black54,
//               child: const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }