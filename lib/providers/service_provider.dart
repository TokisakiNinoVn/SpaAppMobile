import 'package:flutter/material.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/services/customer_service.dart';
import 'package:spa_app/services/service_service.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceService _serviceService = ServiceService();

  bool isLoading = false;

  String? errorMessage;
  List serviceBase = [];
  List selectedServices = [];

  Future<bool> loadListService() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _serviceService.listBaseService();

      // appLog("response: $res");

      // Lấy balance từ response
      serviceBase = res['data'] ?? [];
      // appLog("List data service: $serviceBase");

      return true;
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadSelectedServices() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _serviceService.getSelectedServices();
      // appLog("response: $res");
      selectedServices = res['data'] ?? [];
      // appLog("List data service: $serviceBase");
      return true;
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

}