import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../config/color_config.dart';

class FileUtils {
  Future<File?> cropImage(File imageFile, double ratioX, double ratioY) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt ảnh',
          toolbarColor: ColorConfig.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        // IOSUiSettings(
        //   title: 'Cắt ảnh',
        //   aspectRatioLockEnabled: true,
        //   resetAspectRatioEnabled: false,
        //   aspectRatioPickerButtonHidden: true,
        // ),
        IOSUiSettings(
          title: 'Cắt ảnh',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,

          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: false,
          doneButtonTitle: 'Xong',
          cancelButtonTitle: 'Huỷ',
        )
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

}