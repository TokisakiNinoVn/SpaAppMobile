import 'package:flutter/material.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/services/customer_service.dart';
import 'package:spa_app/services/deposit_service.dart';
import 'package:spa_app/services/service_service.dart';

class DepositProvider extends ChangeNotifier {
  final DepositService _depositService = DepositService();

  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic>? resVerifyDeposit;
  bool? resVerified;
  String? resName;
  double? resBalance;

  Future<bool> verifyDeposit(String query) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _depositService.verifyDeposit(query);
      resVerifyDeposit = res;
      if (res['success'] == true) {
        resVerified = res['data']['verified'];
        resName = res['data']['name'];
        resBalance = res['data']['balance'];
        return true;
      } else {
        errorMessage = res['message'];
        return false;
      }
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}