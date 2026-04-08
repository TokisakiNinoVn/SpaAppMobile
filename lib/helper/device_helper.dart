import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

Future<Map<String, String>> getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final android = await deviceInfo.androidInfo;
    return {
      "device": android.model ?? "",
      "os_version": android.version.release ?? "",
      "brand": android.brand ?? "",
    };
  } else if (Platform.isIOS) {
    final ios = await deviceInfo.iosInfo;
    return {
      "device": ios.utsname.machine ?? "",
      "os_version": ios.systemVersion ?? "",
      "name": ios.name ?? "",
    };
  }

  return {};
}
