import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/handlers/auth_response_handler.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/shared_preferences_helper.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/screens/customer/tabs/components/custom_dialog.dart';
import 'package:spa_app/screens/widgets/role_switcher_card.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:spa_app/services/notification_service.dart';

import '../../../routes/config/customer_router_config.dart';
import '../../../storage/index.dart';
//
// class AccountAdminTab extends StatefulWidget {
//   const AccountAdminTab({super.key});
//
//   @override
//   State<AccountAdminTab> createState() => _AccountAdminTabState();
// }
//
// class _AccountAdminTabState extends State<AccountAdminTab> {
//   Map<String, dynamic>? userInfo;
//   final AuthService authService = AuthService();
//
//   bool isLoading = false;
//   bool get isAdmin => AppConfig.adminPhone.contains(userInfo?['phone']);
//
//   String rolesActive = '';
//   List roles = [];
//
//   @override
//   void initState() {
//     super.initState();
//     loadUserInfo();
//   }
//
//   void loadUserInfo() async {
//     final userInfoJson = await SharedPrefs.getValue(PrefType.string, "inforUserLogin") ?? '';
//     final rolesActiveStr = await SharedPrefs.getValue(PrefType.string, "rolesActive") ?? '';
//     final rolesJsonStr = await SharedPrefs.getValue(PrefType.string, "roles") ?? '[]';
//
//     List<dynamic> rolesList = [];
//     if (rolesJsonStr.isNotEmpty) {
//       try {
//         rolesList = json.decode(rolesJsonStr);
//       } catch (e) {
//         rolesList = [];
//       }
//     }
//
//     Map<String, dynamic>? user;
//     if (userInfoJson.isNotEmpty) {
//       user = json.decode(userInfoJson);
//     }
//
//     setState(() {
//       userInfo = user;
//       rolesActive = rolesActiveStr;
//       roles = rolesList;
//     });
//     appLog("$roles - $rolesActive");
//   }
//
//   // Hiển thị popup xác nhận trước khi đổi role
//   Future<bool> _showRoleConfirmationDialog(String newRole) async {
//     final displayName = _getRoleDisplayName(newRole);
//     return await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             const Text(
//               "Xác nhận đổi vai trò",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         content: Text(
//           "Bạn có chắc muốn chuyển sang vai trò \"$displayName\"?\n"
//               "Giao diện ứng dụng sẽ thay đổi tương ứng.",
//           style: const TextStyle(height: 1.4),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text("Hủy"),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: ColorConfig.primary,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text("Chuyển ngay"),
//           ),
//         ],
//       ),
//     ) ??
//         false;
//   }
//
//   // Thực hiện chuyển role và điều hướng về màn hình tương ứng
//   Future<void> _switchRole(String newRole) async {
//     if (newRole == rolesActive) {
//       SnackBarHelper.showWarning(context, "Bạn đang ở vai trò $_getRoleDisplayName(newRole)");
//       return;
//     }
//
//     final confirmed = await _showRoleConfirmationDialog(newRole);
//     if (!confirmed) return;
//
//     appLog("Switch role: $newRole");
//
//
//     setState(() => isLoading = true);
//
//     try {
//       final response = await authService.switchRoleAccount({
//         "roleChangeTo": newRole,
//       });;
//       await SharedPreferencesHelper.logOut();
//
//       await AuthResponseHandler.handleLoginResponse(
//         context: context,
//         response: response,
//       );
//     } catch (e) {
//       appLog('Lỗi đăng nhập: $e');
//
//       SnackBarHelper.showError(
//         context,
//         "Lỗi kết nối hoặc hệ thống. Vui lòng thử lại!",
//       );
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }
//
//   // Helper lấy tên hiển thị cho role
//   String _getRoleDisplayName(String roleKey) {
//     switch (roleKey) {
//       case 'admin':
//         return 'Quản trị viên';
//       case 'ktv':
//         return 'KTV';
//       case 'customer':
//         return 'Khách hàng';
//       default:
//         return roleKey;
//     }
//   }
//
//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text(
//           "Đăng xuất",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text("Hủy"),
//           ),
//           ElevatedButton.icon(
//             onPressed: () async {
//               await SharedPreferencesHelper.logOut();
//               if (!mounted) return;
//               Navigator.of(context).pop();
//               context.go(CustomerRouterConfig.homeCustomer);
//             },
//             icon: const Icon(Icons.logout),
//             label: const Text("Đăng xuất"),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.redAccent,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Widget hiển thị danh sách role (chips) và hỗ trợ chuyển đổi
//   Widget _buildRoleManagementCard(ThemeData theme) {
//     if (roles.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     final otherRoles = roles
//         .map((e) => e.toString())
//         .where((e) => e != rolesActive)
//         .toList();
//
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: Colors.grey.shade200,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//           BoxShadow(
//             color: Colors.black.withOpacity(0.02),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Vai trò hiện tại",
//             style: TextStyle(
//               fontSize: 13,
//               color: Colors.grey.shade600,
//             ),
//           ),
//
//           const SizedBox(height: 10),
//
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(
//               horizontal: 14,
//               vertical: 14,
//             ),
//             decoration: BoxDecoration(
//               color: ColorConfig.primary.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Row(
//               children: [
//
//                 Expanded(
//                   child: Text(
//                     _getRoleDisplayName(rolesActive),
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//
//                 const Icon(
//                   Icons.check_circle,
//                   color: Colors.green,
//                   size: 20,
//                 ),
//               ],
//             ),
//           ),
//
//           if (otherRoles.isNotEmpty) ...[
//             const SizedBox(height: 20),
//
//             Text(
//               "Chuyển vai trò",
//               style: TextStyle(
//                 fontSize: 13,
//                 color: ColorConfig.textBlack,
//               ),
//             ),
//
//             const SizedBox(height: 12),
//
//             Wrap(
//               spacing: 10,
//               runSpacing: 10,
//               children: otherRoles.map((role) {
//                 return InkWell(
//                   borderRadius: BorderRadius.circular(999),
//                   onTap: () => _switchRole(role),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 15,
//                       vertical: 7,
//                     ),
//                     decoration: BoxDecoration(
//                       color: ColorConfig.primary,
//                       borderRadius: BorderRadius.circular(999),
//                       border: Border.all(
//                         color: Colors.grey.shade200,
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           _getRoleDisplayName(role),
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                             color: ColorConfig.textWhite
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//             )
//           ],
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       body: SafeArea(
//         child: Container(
//           // color: ColorConfig.primaryBackground,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // const SizedBox(height: 50),
//
//                 Center(
//                   child: Column(
//                     children: [
//                       Text(
//                         "Tài khoản quản trị",
//                         style:TextStyle(
//                           color: Colors.black,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 // Card thông tin tài khoản
//                 Card(
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Thông tin tài khoản",
//                           style: theme.textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         if (userInfo != null) ...[
//                           _buildInfoRow(
//                             icon: Icons.phone,
//                             label: "Số điện thoại",
//                             value: userInfo!['phone'] ?? '',
//                           ),
//                           const Divider(height: 24),
//                           _buildInfoRow(
//                             icon: Icons.lock,
//                             label: "Mật khẩu",
//                             value: userInfo!['password'] ?? '',
//                             obscureValue: true,
//                           ),
//                         ] else
//                           const Center(
//                             child: CircularProgressIndicator(),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Khu vực quản lý role (thêm nút và các role)
//                 if(isAdmin)...[
//                   _buildRoleManagementCard(theme),
//                 ],
//
//                 // Nút đăng xuất
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () => _showLogoutDialog(context),
//                     icon: const Icon(Icons.logout),
//                     label: const Text("Đăng xuất"),
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       backgroundColor: Colors.redAccent,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(40),
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 // Footer
//                 Center(
//                   child: Text(
//                     "Phiên bản 1.0.0",
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow({
//     required IconData icon,
//     required String label,
//     required String value,
//     bool obscureValue = false,
//   }) {
//     return Row(
//       children: [
//         Icon(icon, color: Colors.blueGrey, size: 20),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 obscureValue ? "••••••••" : value,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

class AccountAdminTab extends StatefulWidget {
  const AccountAdminTab({super.key});

  @override
  State<AccountAdminTab> createState() => _AccountAdminTabState();
}

class _AccountAdminTabState extends State<AccountAdminTab> {
  Map<String, dynamic>? userInfo;
  final AuthService authService = AuthService();

  bool isLoading = false;

  String rolesActive = '';
  List<String> roles = [];
  bool get isAdmin => AppConfig.adminPhone.contains(userInfo?['phone']);

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final userInfoJson = await SharedPrefs.getValue(PrefType.string, "inforUserLogin") ?? '';
    final rolesActiveStr = await SharedPrefs.getValue(PrefType.string, "rolesActive") ?? '';
    final rolesJsonStr = await SharedPrefs.getValue(PrefType.string, "roles") ?? '[]';

    List<String> rolesList = [];
    if (rolesJsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(rolesJsonStr);
        rolesList = decoded.map((e) => e.toString()).toList();
      } catch (e) {
        rolesList = [];
      }
    }

    Map<String, dynamic>? user;
    if (userInfoJson.isNotEmpty) {
      user = json.decode(userInfoJson);
    }

    if (mounted) {
      setState(() {
        userInfo = user;
        rolesActive = rolesActiveStr;
        roles = rolesList;
      });
    }
    // appLog("$roles - $rolesActive");
  }

  // Xử lý chuyển đổi vai trò (đã tách logic khỏi UI)
  Future<void> _handleSwitchRole(String newRole) async {
    if (newRole == rolesActive) {
      SnackBarHelper.showWarning(context, "Bạn đang ở vai trò ${_getRoleDisplayName(newRole)}");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await authService.switchRoleAccount({
        "roleChangeTo": newRole,
      });
      await SharedPreferencesHelper.logOut();

      await AuthResponseHandler.handleLoginResponse(
        context: context,
        response: response,
      );
    } catch (e) {
      appLog('Lỗi chuyển vai trò: $e');
      SnackBarHelper.showError(
        context,
        "Lỗi kết nối hoặc hệ thống. Vui lòng thử lại!",
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getRoleDisplayName(String roleKey) {
    switch (roleKey) {
      case 'admin':
        return 'Quản trị viên';
      case 'ktv':
        return 'KTV';
      case 'customer':
        return 'Khách hàng';
      case 'quanly':
        return 'Quản lý';
      default:
        return "$roleKey : Không rõ";
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Đăng xuất",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await SharedPreferencesHelper.logOut();
              if (!mounted) return;
              Navigator.of(context).pop();
              context.go(CustomerRouterConfig.homeCustomer);
            },
            icon: const Icon(Icons.logout),
            label: const Text("Đăng xuất"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Tài khoản quản trị",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card thông tin tài khoản
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thông tin tài khoản",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (userInfo != null) ...[
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: "Số điện thoại",
                          value: userInfo!['phone'] ?? '',
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.lock,
                          label: "Mật khẩu",
                          value: userInfo!['password'] ?? '',
                          obscureValue: true,
                        ),
                      ] else
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sử dụng widget RoleSwitcherCard đã tách
              if (isAdmin && roles.isNotEmpty)
                RoleSwitcherCard(
                  roles: roles,
                  activeRole: rolesActive,
                  onSwitchRole: _handleSwitchRole,
                  isSwitching: isLoading,
                ),

              // Nút đăng xuất
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Đăng xuất"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Footer
              Center(
                child: Text(
                  "Phiên bản 1.0.0",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool obscureValue = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                obscureValue ? "••••••••" : value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}