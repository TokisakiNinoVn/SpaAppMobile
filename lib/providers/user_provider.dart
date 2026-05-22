import 'package:flutter/material.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/services/customer_service.dart';
import 'package:spa_app/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  final UserService _userService = UserService();

  bool isLoading = false;

  String? errorMessage;
  int nowBalance = 0;

  Future<bool> loadBalanceCustomer() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _customerService.balanceCustomerService();

      appLog("response: $res");

      // Lấy balance từ response
      nowBalance = res['data']['balance'] ?? 0;
      appLog("nowBalance: $nowBalance");

      return true;
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createManagementAccount(Map<String, dynamic> data) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _userService.createManagementAccountService(data);
      // appLog("$res");
      // Lấy balance từ response
      // nowBalance = res['data']['balance'] ?? 0;
      // appLog("nowBalance: $nowBalance");

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