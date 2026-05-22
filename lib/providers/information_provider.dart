import 'package:flutter/material.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/services/customer_service.dart';
import 'package:spa_app/services/information_service.dart';

class InformationProvider extends ChangeNotifier {
  final InformationService _informationService = InformationService();

  bool isLoadingList = false;
  bool isLoadingSearchPlatformFees = false;

  String? updatingId;

  String? errorMessage;
  dynamic platformFee;

  List platformFees = [];
  Map<String, dynamic> detailPlatformFees = {};

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

  Future<bool> searchPlatformFees(String typePlatformFees) async {
    isLoadingSearchPlatformFees = true;
      notifyListeners();

      try {
        final res = await _informationService.searchPlatformFees(typePlatformFees);
        // appLog("${res['data']['percentage']}");

        platformFee = res['data']['percentage'] ?? 0;

        // appLog("${platformFee}");
        return true;
      } catch (e) {
        errorMessage = 'Đã xảy ra lỗi: $e';
        return false;
      } finally {
        isLoadingSearchPlatformFees = false;
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