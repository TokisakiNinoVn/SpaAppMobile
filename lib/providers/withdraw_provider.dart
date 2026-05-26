import 'package:flutter/material.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/services/customer_service.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/services/withdraw_service.dart';

class WithdrawProvider extends ChangeNotifier {
  final WithdrawService _withdrawService  = WithdrawService();

  bool isLoading = false;

  String? errorMessage;
  // int nowBalance = 0;
  bool hasFirstWithdrawalToday = true;
  dynamic feePercentWithdraw;

  Future<bool> checkHasFirstWithdrawalToday() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _withdrawService.hasFirstWithdrawalToday();

      // appLog("response: $res");

      hasFirstWithdrawalToday = res['data']['hasFirstWithdrawalToday'] ?? true;
      feePercentWithdraw = res['data']['feePercent'] ?? true;
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

  Future<bool> createRequestWithdraw(Map<String, dynamic> data) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _withdrawService.createRequest(data);
      appLog("${response}");
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