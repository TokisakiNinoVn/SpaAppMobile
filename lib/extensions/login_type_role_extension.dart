// File: lib/core/extensions/login_type_role_extension.dart

import 'package:spa_app/config/role_user_config.dart';
import 'package:spa_app/enums/login_type_role.dart';
import 'package:spa_app/models/role_user_model.dart';

extension LoginTypeRoleExtension on LoginTypeRole {

  RoleUserModel get config => RoleUserConfig.roles[this]!;

  /// Value gửi API
  String get value => config.value;

  /// Tên hiển thị UI
  String get displayName => config.display;
  String get shortDisplay => config.shortDisplay;

  /// Kiểm tra role
  bool get isCustomer => this == LoginTypeRole.customer;
  bool get isKtv => this == LoginTypeRole.ktv;
  bool get isAdmin => this == LoginTypeRole.admin;
  bool get isQuanly => this == LoginTypeRole.quanly;

  /// Parse từ API/string
  static LoginTypeRole fromValue(String? value) {
    return RoleUserConfig.roles.entries
      .firstWhere(
        (e) => e.value.value == value,
        orElse: () => MapEntry(
          LoginTypeRole.customer,
          RoleUserConfig.roles[LoginTypeRole.customer]!,
        ),
    ).key;
  }
}