// File: lib/data/configs/role_user_config.dart

import 'package:spa_app/enums/login_type_role.dart';
import 'package:spa_app/models/role_user_model.dart';

class RoleUserConfig {
  static final Map<LoginTypeRole, RoleUserModel> roles = {
    LoginTypeRole.customer: RoleUserModel(
      name: 'Khách hàng',
      display: 'Khách hàng',
      shortDisplay: "KH",
      value: 'customer',
    ),

    LoginTypeRole.ktv: RoleUserModel(
      name: 'Kỹ thuật viên',
      display: 'Kỹ thuật viên',
      shortDisplay: "KTV",
      value: 'ktv',
    ),
    LoginTypeRole.admin: RoleUserModel(
      name: 'Admin',
      display: 'Admin',
      shortDisplay: "ADM",
      value: 'admin',
    ),
    LoginTypeRole.quanly: RoleUserModel(
      name: 'Quản lý',
      display: 'Quản lý',
      shortDisplay: "QL",
      value: 'quanly',
    ),
  };
}