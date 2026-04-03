import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationHelper {
  // static Future<bool> isLocationReady() async {
  //   // 1. Kiểm tra permission
  //   var permission = await Permission.location.status;
  //
  //   if (permission.isDenied) {
  //     permission = await Permission.location.request();
  //     if (!permission.isGranted) {
  //       print('❌ Permission bị từ chối');
  //       return false;
  //     }
  //   }
  //
  //   if (permission.isPermanentlyDenied) {
  //     print('⚠️ Permission bị từ chối vĩnh viễn');
  //     await openAppSettings();
  //     return false;
  //   }
  //
  //   // 2. Kiểm tra GPS (Location Service)
  //   final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     print('❌ GPS đang tắt');
  //     await Geolocator.openLocationSettings();
  //     return false;
  //   }
  //
  //   // OK hết
  //   print('✅ Location sẵn sàng');
  //   return true;
  // }

  static Future<bool> isLocationReady() async {
    // 1. Kiểm tra permission (KHÔNG request)
    final permission = await Permission.location.status;

    if (permission.isDenied || permission.isRestricted) {
      print('❌ Chưa có quyền truy cập vị trí');
      return false;
    }

    if (permission.isPermanentlyDenied) {
      print('⚠️ Quyền vị trí bị từ chối vĩnh viễn');
      return false;
    }

    // 2. Kiểm tra GPS (Location Service)
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ GPS đang tắt');
      return false;
    }

    // OK hết
    print('✅ Location sẵn sàng');
    return true;
  }

  // static Future<Position?> getCurrentLocation() async {
  //   HapticFeedback.lightImpact();
  //
  //   try {
  //     // 1. Check permission
  //     final permission = await Permission.location.status;
  //     if (!permission.isGranted) {
  //       print('❌ Chưa có quyền vị trí');
  //       return null;
  //     }
  //
  //     // 2. Check GPS
  //     final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       print('❌ GPS đang tắt');
  //       return null;
  //     }
  //
  //     // 3. Lấy vị trí
  //     final pos = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.medium,
  //     );
  //
  //     return pos;
  //   } catch (e) {
  //     print('❌ Lỗi lấy vị trí: $e');
  //     return null;
  //   }
  // }

  static Future<Position?> getSharedPreferencesLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lat = prefs.getDouble('lat');
      final long = prefs.getDouble('lng');

      if (lat == null || long == null) {
        print('⚠️ Không có dữ liệu vị trí trong SharedPreferences');
        return null;
      }

      final pos = Position(
        latitude: lat,
        longitude: long,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      return pos;
    } catch (e) {
      print('❌ Lỗi lấy vị trí: $e');
      return null;
    }
  }


  static Future<Position?> getCurrentLocation() async {
    HapticFeedback.lightImpact();

    try {
      // 1. Check permission
      var permission = await Permission.location.status;

      // 2. Nếu chưa có → xin quyền
      if (permission.isDenied || permission.isRestricted) {
        permission = await Permission.location.request();

        if (!permission.isGranted) {
          print('❌ Người dùng từ chối cấp quyền vị trí');
          return null;
        }
      }

      // 3. Nếu bị từ chối vĩnh viễn
      if (permission.isPermanentlyDenied) {
        print('⚠️ Quyền vị trí bị từ chối vĩnh viễn');
        return null;
      }

      // 4. Check GPS
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ GPS đang tắt');
        return null;
      }

      // 5. Lấy vị trí
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      return pos;
    } catch (e) {
      print('❌ Lỗi lấy vị trí: $e');
      return null;
    }
  }

}
