// lib/utils/crop_editor_helper.dart
import 'dart:typed_data';
import 'dart:ui';
import 'package:extended_image/extended_image.dart';
import 'package:image/image.dart' as img;

Future<Uint8List?> cropImageDataWithDartLibrary({
  required ExtendedImageEditorState state,
}) async {
  final Rect? cropRect = state.getCropRect();
  if (cropRect == null) return null;

  final Uint8List data = state.rawImageData;

  img.Image? src = img.decodeImage(data);
  if (src == null) return null;

  final img.Image cropped = img.copyCrop(
    src,
    x: cropRect.left.toInt(),
    y: cropRect.top.toInt(),
    width: cropRect.width.toInt(),
    height: cropRect.height.toInt(),
  );

  return Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
}