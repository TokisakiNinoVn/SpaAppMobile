import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:spa_app/routes/config/technician_router_config.dart';

import '../storage/index.dart';

class AuthResponseHandler {
  static Future<void> handleLoginResponse({
    required BuildContext context,
    required Map<String, dynamic> response,
  }) async {
    if (response['token'] == null) {
      SnackBarHelper.showError(
        context,
        response['message'] ?? "Đăng nhập thất bại",
      );
      return;
    }

    final data = response['data'] ?? {};

    final role = data['rolesActive'];
    final isHaveTechnician = data['isHaveTechnician'] ?? false;

    // ===== SAVE COMMON DATA =====
    await SharedPrefs.saveValue(PrefType.string, "token", response['token']);
    await SharedPrefs.saveValue(PrefType.string, "role", role);
    await SharedPrefs.saveValue(PrefType.bool, "isTechnicianActive", data['isTechnicianActive'] ?? false);
    await SharedPrefs.saveValue(PrefType.string, "inforUserLogin", data);
    await SharedPrefs.saveValue(PrefType.string, "rolesActive", role);
    await SharedPrefs.saveValue(PrefType.string, "roles", data['roles']);
    await SharedPrefs.saveValue(PrefType.bool, "isLogin", true);

    // ===== CUSTOMER =====
    if (role == 'customer') {
      await SharedPrefs.saveValue(PrefType.string, "customerProfile", data['customerProfile'] ?? {});
      await SharedPrefs.saveValue(PrefType.int, "balance", data['customerProfile']?['balance'] ?? 0);
      await SharedPrefs.saveValue(PrefType.bool, "isHaveTechnician", isHaveTechnician);

      context.go(CustomerRouterConfig.homeCustomer);
      return;
    }

    // ===== TECHNICIAN =====
    if (role == 'ktv') {
      if (isHaveTechnician) {
        await SharedPrefs.saveValue(PrefType.string, 'technician', data['technicianProfile']);
        await SharedPrefs.saveValue(PrefType.string, 'serviceIds', jsonEncode(data['technicianProfile']?['serviceIds'] ?? []));
        await SharedPrefs.saveValue(PrefType.string, 'inforService', jsonEncode(data['inforService'] ?? []));

        context.go(TechnicianRouterConfig.homeTechnician);
      } else {
        SnackBarHelper.showWarning(
          context,
          "Bạn đã đăng ký tài khoản nhưng chưa tạo hồ sơ!",
        );

        context.go(GlobalRouterConfig.createTechnician);
      }

      return;
    }

    if (role == 'admin') {
      context.go('/home-admin');
      return;
    }

    if (role == 'quanly') {
      context.go('/home-quanly');
    }
    // ===== UNKNOWN ROLE =====
    SnackBarHelper.showWarning(
      context,
      "Không xác định role: $role",
    );
  }
}