import 'package:flutter/material.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/services/customer_service.dart';
import 'package:spa_app/services/information_service.dart';
//
// class InformationProvider extends ChangeNotifier {
//   final InformationService _informationService = InformationService();
//
//   bool isLoadingList = false;
//   bool isLoadingUpdate = false;
//
//   String? errorMessage;
//
//   List platformFees = [];
//
//   Future<bool> list() async {
//     isLoadingList = true;
//     errorMessage = null;
//     notifyListeners();
//
//     try {
//       final res = await _informationService.listPlatformFees();
//
//       appLog("response: $res");
//
//       // Lấy balance từ response
//       platformFees = res['data'] ?? [];
//       appLog("nowBalance: $platformFees");
//
//       return true;
//     } catch (e) {
//       errorMessage = 'Đã xảy ra lỗi: $e';
//       return false;
//     } finally {
//       isLoadingList = false;
//       notifyListeners();
//     }
//   }
//
//   Future<bool> update(String id, Map<String, dynamic> body) async {
//     isLoadingUpdate = true;
//     errorMessage = null;
//     notifyListeners();
//
//     try {
//       final res = await _informationService.updatePlatformFees(id, body);
//       appLog("response: $res");
//
//
//       return true;
//     } catch (e) {
//       errorMessage = 'Đã xảy ra lỗi: $e';
//       return false;
//     } finally {
//       isLoadingUpdate = false;
//       notifyListeners();
//     }
//   }
// }

class InformationProvider extends ChangeNotifier {
  final InformationService _informationService = InformationService();

  bool isLoadingList = false;

  String? updatingId;

  String? errorMessage;

  List platformFees = [];

  Future<bool> list() async {
    isLoadingList = true;
    notifyListeners();

    try {
      final res = await _informationService.listPlatformFees();

      platformFees = res['data'] ?? [];

      return true;
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoadingList = false;
      notifyListeners();
    }
  }

  Future<bool> update(String id, Map<String, dynamic> body) async {
    updatingId = id;
    notifyListeners();

    try {
      var response = await _informationService.updatePlatformFees(id, body);
      if(response['success'] == true) {
        final index = platformFees.indexWhere((e) => e['_id'] == id);
        if (index != -1) {
          platformFees[index]['percentage'] = body['percentage'];
        }
        return true;
      }

      appLog("Không thể cập nhật: $response");
      errorMessage = 'Đã xảy ra lỗi: $response';
      return false;

    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      updatingId = null;
      notifyListeners();
    }
  }
}