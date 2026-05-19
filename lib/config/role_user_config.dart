// File: lib/data/configs/role_user_config.dart

import 'package:clean_water/data/enums/login_type_role.dart';
import 'package:clean_water/data/models/role_user_model.dart';

class RoleUserConfig {
  static final Map<LoginTypeRole, RoleUserModel> roles = {
    LoginTypeRole.customer: RoleUserModel(
      name: 'Khách hàng',
      display: 'Khách hàng',
      value: 'khach_hang',
    ),

    LoginTypeRole.staff: RoleUserModel(
      name: 'Nhân viên',
      display: 'Nhân viên',
      value: 'nhan_vien',
    ),
  };
}