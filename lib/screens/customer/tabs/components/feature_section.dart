import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/handlers/auth_response_handler.dart';
import 'package:spa_app/helper/check_login_helper.dart';
import 'package:spa_app/helper/shared_preferences_helper.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:spa_app/services/user_service.dart';

import '../../../../storage/index.dart';

class FeatureSection extends StatefulWidget {
  const FeatureSection({super.key});

  @override
  State<FeatureSection> createState() => _FeatureSectionState();
}

class _FeatureSectionState extends State<FeatureSection> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  bool _isLogin = false;
  bool _isSwitchingRole = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();
    if (mounted) {
      setState(() => _isLogin = loggedIn);
    }
  }

  Future<void> _changeRole() async {
    setState(() => _isSwitchingRole = true);
    try {
      final response = await _authService.switchRoleAccount({
        "roleChangeTo": "ktv",
      });
      if (!mounted) return;

      await SharedPreferencesHelper.logOut();

      await AuthResponseHandler.handleLoginResponse(
        context: context,
        response: response,
      );


      // if (response['success'] == true) {
      //   SnackBarHelper.showSuccess(context, "Chuyển đổi vai trò thành công!");
      //   await SharedPreferencesHelper.logOut();
      //   if (mounted) {
      //     context.go(GlobalRouterConfig.loginOTP);
      //   }
      // } else {
      //   SnackBarHelper.showError(
      //     context,
      //     response['message'] ?? "Lỗi chuyển đổi vai trò!",
      //   );
      // }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, "Lỗi: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSwitchingRole = false);
      }
    }
  }

  // void _showRoleSwitchDialog() {
  //   showDialog<bool>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => AlertDialog(
  //       title: const Text('Chuyển đổi vai trò'),
  //       content: const Text('Bạn muốn chuyển sang vai trò kỹ thuật viên?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Hủy'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: ColorConfig.primary,
  //           ),
  //           child: Text(
  //             'Chuyển đổi',
  //             style: TextStyle(color: ColorConfig.textWhite),
  //           ),
  //         ),
  //       ],
  //     ),
  //   ).then((confirmed) {
  //     if (confirmed == true) {
  //       _changeRole();
  //     }
  //   });
  // }

  void _showRoleSwitchDialog() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Chuyển vai trò'),
        content: const Text(
          'Bạn có muốn chuyển sang chế độ Kỹ thuật viên không?\n\n'
              'Sau khi chuyển, giao diện và các chức năng liên quan đến kỹ thuật viên sẽ được hiển thị.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Để sau',
              style: TextStyle(
                color: ColorConfig.textBlack
              ),
            ),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                ColorConfig.primary,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Tiếp tục',
              style: TextStyle(
                  color: ColorConfig.textWhite
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _changeRole();
      }
    });
  }

  Future<bool> _hasTechnicianProfile() async {
    return await SharedPrefs.getValue(PrefType.bool, 'isHaveTechnician') ?? false;
  }

  void _handleRegisterTap() async {
    if (_isLogin) {
      final hasTechnician = await _hasTechnicianProfile();
      if (hasTechnician) {
        _showRoleSwitchDialog();
      } else {
        if (mounted) {
          context.go(CustomerRouterConfig.createProfileTechnician);
        }
      }
    } else {
      if (mounted) {
        context.go(GlobalRouterConfig.signup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      child: Column(
        children: [
          _buildRegisterCard(),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConfig.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đăng ký trở thành Kỹ thuật viên',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Thời gian linh hoạt, thu nhập xứng đáng, hỗ trợ tận tâm.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),

                // CTA
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _isSwitchingRole ? null : _handleRegisterTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isSwitchingRole ? 'Đang xử lý...' : 'Tham gia ngay',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorConfig.primary,
                        ),
                      ),
                      if (!_isSwitchingRole) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: ColorConfig.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // RIGHT ICON BOX
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://i.pinimg.com/736x/d4/7c/5f/d47c5f007c80eb65409c173d10dabef3.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}