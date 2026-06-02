import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/handlers/auth_response_handler.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/user_provider.dart';
import 'package:spa_app/screens/widgets/role_switcher_card.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/helper/shared_preferences_helper.dart';
import 'package:spa_app/routes/config/global_router_config.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/services/user_service.dart';

import '../../../helper/check_login_helper.dart';
import '../../../storage/index.dart';
import 'components/SpaDialog.dart';
import 'components/MenuEntry.dart';
import '../../../models/Lang.dart';
import 'components/LanguageSheet.dart';

// Simple color palette
const _kBlack = Color(0xFF1A1A1A);
const _kGray = Color(0xFF666666);
const _kLightGray = Color(0xFFF5F5F5);
const _kWhite = Colors.white;
const _kRed = Color(0xFFE74C3C);

class AccountCustomerTab extends StatefulWidget {
  const AccountCustomerTab({super.key});

  @override
  State<AccountCustomerTab> createState() => _AccountCustomerTabState();
}

class _AccountCustomerTabState extends State<AccountCustomerTab>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final AuthService authService = AuthService();

  bool isLoading = false;
  bool _isSwitchingRole = false;
  bool isHasTechnicianProfile = false;
  bool _isLogin = false;
  Map<String, dynamic>? inforUser;
  String _selectedLang = 'vi';
  int balance = 0;
  bool _isRefreshing = false;

  String rolesActive = '';
  List<String> roles = [];
  bool isAdmin = false;
  String _errorMessage = '';
  bool _isLoading = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _checkLogin();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      var response = await _reloadAllData();
      if (mounted) {
        SnackBarHelper.showSuccess(context, "Đã cập nhật thông tin");
      }

    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Cập nhật thất bại: $e');
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _reloadAllData() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();

    if (loggedIn) {
      await _loadInforUser();
      // balance = await SharedPrefs.getValue(PrefType.int, "balance") ?? 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBalanceNow();
      });
      await _fetchLatestUserData();

    } else {
      setState(() {
        _isLogin = false;
        inforUser = null;
        balance = 0;
      });
    }

    if (!_fadeCtrl.isCompleted) _fadeCtrl.forward();
  }

  Future<void> _fetchLatestUserData() async {
    try {
      final response = await _userService.getDataUserLoginService();
      if (response['success'] == true && mounted) {
        final userData = response['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('inforUserLogin', jsonEncode(userData));

        if (userData['customerProfile'] != null) {
          final newBalance = userData['customerProfile']['balance'] ?? balance;
          await SharedPrefs.saveValue(PrefType.int, "balance", newBalance);
          setState(() => balance = newBalance);
        }

        setState(() => inforUser = userData);
      }
    } catch (e) {
      appLog("⚠️ Cannot fetch latest data: $e");
    }
  }

  Future<void> _checkLogin() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();
    if (loggedIn) await _loadInforUser();
    if (!mounted) return;
    setState(() => _isLogin = loggedIn);
    _fadeCtrl.forward();
  }

  Future<void> _loadInforUser() async {
    // balance = await SharedPrefs.getValue(PrefType.int, "balance") ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalanceNow();
    });
    isHasTechnicianProfile = await SharedPrefs.getValue(PrefType.bool, 'isHaveTechnician') ?? false;

    final rolesActiveStr = await SharedPrefs.getValue(PrefType.string, "role") ?? '';
    final rolesJsonStr = await SharedPrefs.getValue(PrefType.string, "roles") ?? '[]';

    List<String> rolesList = [];
    if (rolesJsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(rolesJsonStr);
        rolesList = decoded.map((e) => e.toString()).toList();
      } catch (e) {
        rolesList = [];
      }
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('inforUserLogin');
      final data = jsonString != null ? jsonDecode(jsonString) as Map<String, dynamic> : null;
      if (mounted)
      {
        setState(() {
          inforUser = data;
          rolesActive = rolesActiveStr;
          roles = rolesList;
          isAdmin = AppConfig.adminPhone.contains(inforUser?['phone']);
        });

      }
    } catch (e) {
      debugPrint('❌ Parse error: $e');
      if (mounted) setState(() => inforUser = null);
    }
  }

  Future<void> _loadBalanceNow() async {
    final provider = context.read<UserProvider>();
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await provider.loadBalanceUser();
      balance = provider.nowBalance;

      setState(() {
        balance = balance ?? 0;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error get now balance: $e');
    }
  }

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
        return 'Admin';
      case 'ktv':
        return 'KTV';
      case 'customer':
        return 'Khách hàng';
      default:
        return roleKey;
    }
  }

  Future<void> _changeRole() async {
    setState(() => _isSwitchingRole = true);
    try {
      // final response = await _userService.changeRoleService({
      final response = await authService.switchRoleAccount({
        "roleChangeTo": "ktv",
      });

      await SharedPreferencesHelper.logOut();

      await AuthResponseHandler.handleLoginResponse(
        context: context,
        response: response,
      );

      // appLog("$response");
      // if (!mounted) return;
      // if (response['success'] == true) {
      //   SnackBarHelper.showSuccess(context, "Chuyển đổi vai trò thành công!");
      //   await SharedPreferencesHelper.logOut();
      //   if (mounted) context.go(GlobalRouterConfig.loginOTP);
      // } else {
      //   SnackBarHelper.showError(context, "Lỗi chuyển đổi vai trò!");
      // }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, "Lỗi: $e");
    } finally {
      if (mounted) setState(() => _isSwitchingRole = false);
    }
  }

  void _showRoleSwitchDialog() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chuyển vai trò'),
        content: const Text(
          'Bạn có muốn chuyển sang chế độ Kỹ thuật viên không?\n\n'
              'Sau khi chuyển, giao diện và các chức năng liên quan đến kỹ thuật viên sẽ được hiển thị.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: ColorConfig.primary),
            child: Text('Tiếp tục', style: TextStyle(color: ColorConfig.textWhite),),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _changeRole();
      }
    });
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => SpaDialog(
        iconColor: _kRed,
        title: 'Đăng xuất',
        body: 'Bạn có chắc chắn muốn đăng xuất?',
        cancelLabel: 'Hủy',
        confirmLabel: 'Đăng xuất',
        confirmColor: _kRed,
        onConfirm: () {},
      ),
    );

    if (result == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: _kBlack)),
      );

      try {
        await SharedPreferencesHelper.logOut();
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pushReplacement(GlobalRouterConfig.loginOTP);
          });
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        SnackBarHelper.showError(context, "Lỗi đăng xuất: $e");
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    const minWithdraw = 10000;

    // Có tiền và đủ điều kiện rút
    if (balance >= minWithdraw) {
      await showDialog(
        context: context,
        builder: (_) => SpaDialog(
          title: 'Không thể xóa tài khoản',
          iconColor: _kRed,
          body:
          'Bạn hiện còn ${FormatHelper.formatPrice(balance)}đ trong tài khoản.\n\n'
              'Vui lòng rút toàn bộ số dư trước khi thực hiện xóa tài khoản.',
          cancelLabel: 'Đóng',
          confirmLabel: 'Đi rút tiền',
          onConfirm: () {
            context.push(CustomerRouterConfig.createReqWithdraw);
            appLog("Vô đây");
          },
          confirmColor: ColorConfig.primary,
        ),
      );
      return;
    }

    String body =
        'Bạn có chắc chắn muốn xóa tài khoản?\n\n'
        'Tài khoản sẽ bị vô hiệu hóa ngay sau khi xác nhận và không thể khôi phục.\n'
        'Dữ liệu sẽ được xóa hoàn toàn sau 30 ngày.';

    // Số dư nhỏ hơn mức rút tối thiểu
    if (balance > 0 && balance < minWithdraw) {
      body =
      'Bạn hiện còn ${FormatHelper.formatPrice(balance)}đ trong tài khoản.\n\n'
          'Số dư này chưa đạt mức rút tối thiểu ${FormatHelper.formatPrice(balance)}đ.\n'
          'Nếu tiếp tục xóa tài khoản, số dư còn lại sẽ bị hủy và không thể hoàn lại.\n\n'
          'Bạn vẫn muốn tiếp tục?';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SpaDialog(
        iconColor: _kRed,
        title: 'Xóa tài khoản',
        body: body,
        cancelLabel: 'Hủy',
        confirmLabel: 'Xóa tài khoản',
        confirmColor: _kRed,
        onConfirm: () {},
      ),
    );

    if (result == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: _kBlack)),
      );

      try {
        var res = await _userService.deleteAccountService();
        // appLog("Xóa tài khoản: $res");
        if(res['success']) {
          SnackBarHelper.showSuccess(context, res['message']);

          await SharedPreferencesHelper.logOut();
          if (mounted) Navigator.of(context).pop();
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.pushReplacement(GlobalRouterConfig.loginOTP);
            });
          }
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        SnackBarHelper.showError(context, "Lỗi xóa tài khoản: $e");
      }
    }
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageSheet(
        selected: _selectedLang,
        onSelect: (code) => setState(() => _selectedLang = code),
      ),
    );
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
    // appLog("$isAdmin - $rolesActive - $roles");
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        color: _kBlack,
        backgroundColor: _kWhite,
        strokeWidth: 2,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      if (_isLogin) ...[
                        _buildUserHeader(),
                        const SizedBox(height: 10),

                        if (isAdmin && roles.isNotEmpty)
                          RoleSwitcherCard(
                            roles: roles,
                            activeRole: rolesActive,
                            onSwitchRole: _handleSwitchRole,
                            isSwitching: isLoading,
                          ),
                        // const SizedBox(height: 10),
                        _buildBalanceSection(),
                        const SizedBox(height: 24),
                        _buildMenuSection(),
                        const SizedBox(height: 24),
                        _buildAccountActions(),
                      ] else ...[
                        _buildGuestBanner(),
                        // const SizedBox(height: 24),
                        _buildActionButton(
                          label: 'Đăng nhập',
                          icon: Icons.login_rounded,
                          filled: true,
                          onTap: () => context.go(GlobalRouterConfig.loginOTP),
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          label: 'Đăng ký',
                          icon: Icons.person_add_alt_1_rounded,
                          onTap: () => context.go(GlobalRouterConfig.register),
                        ),
                      ],

                      const SizedBox(height: 24),
                      // _buildLanguageCard(),
                      // const SizedBox(height: 24),
                      _buildSupportSection(),

                      if (_isRefreshing)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _kBlack),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kLightGray,
          ),
          child: const CircleAvatar(
            radius: 35,
            backgroundImage: AssetImage('lib/assets/images/img_3.png'),
            backgroundColor: _kLightGray,
          ),
        ),

        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                inforUser?['data']?['fullName'] ??
                    inforUser?['data']?['phone'] ??
                    inforUser?['fullName'] ??
                    inforUser?['phone'] ??
                    'Khách hàng',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kBlack,
                ),
              ),

              if (inforUser?['data']?['phone'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    inforUser!['data']!['phone'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kGray,
                    ),
                  ),
                ),

              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _kLightGray,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Text(
                  'Khách hàng',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _kGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kLightGray,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👉 Hàng trên: Số dư
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 22,
                  color: ColorConfig.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Số dư ví: ${FormatHelper.formatPrice(balance)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kBlack,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Nạp tiền',
                  icon: Icons.add_card_rounded,
                  filled: true,
                  onTap: () => context.go(CustomerRouterConfig.choosePackage),
                  paddingVertical: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Rút tiền',
                  icon: Icons.arrow_forward_outlined,
                  filled: false,
                  onTap: () {
                    context.push(CustomerRouterConfig.createReqWithdraw);
                  },
                  paddingVertical: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildMenuSection() {
    final items = [
      MenuEntry(icon: Icons.person_outline_rounded, label: 'Thông tin cá nhân', route: CustomerRouterConfig.updateProfile),
      // MenuEntry(icon: Icons.favorite_border_rounded, label: 'Kỹ thuật viên yêu thích', route: CustomerRouterConfig.listLike),
      // MenuEntry(icon: Icons.discount_outlined, label: 'Mã giảm giá', route: CustomerRouterConfig.listDiscountScreen),
      MenuEntry(icon: Icons.location_on_outlined, label: 'Địa chỉ của tôi', route: CustomerRouterConfig.listAddress),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kLightGray),
      ),
      child: Column(
        children: [
          ...items.map((item) => _buildMenuItem(item)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuEntry entry) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: () {
        if (entry.type == 'web') {
          launchUrl(Uri.parse(entry.route));
        } else if (entry.route.isNotEmpty) {
          context.go(entry.route);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(entry.icon, size: 20, color: _kGray),
            const SizedBox(width: 14),
            Expanded(
              child: Text(entry.label, style: const TextStyle(fontSize: 14, color: _kBlack)),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _kGray),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kLightGray),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            onTap: _isSwitchingRole ? null : _handleRegisterTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.change_circle, size: 20, color: _kGray),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(isHasTechnicianProfile ? 'Chuyển đổi tài khoản KTV' : 'Trở thành Cộng tác viên',
                      style: TextStyle(fontSize: 14, color: _isSwitchingRole ? _kGray : _kBlack),
                    ),
                  ),
                  if (_isSwitchingRole)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _kBlack))
                  else
                    const Icon(Icons.chevron_right_rounded, size: 18, color: _kGray),
                ],
              ),
            ),
          ),
          Divider(color: _kLightGray, height: 1),
          InkWell(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            onTap: _showLogoutDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: 20, color: _kRed),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Đăng xuất', style: TextStyle(fontSize: 14, color: _kRed)),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: _kRed),
                ],
              ),
            ),
          ),
          // const SizedBox(height: 8),
          Divider(color: _kLightGray, height: 1),
          // const SizedBox(height: 8),
          InkWell(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            onTap: _showDeleteAccountDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, size: 20, color: _kRed),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Xóa tài khoản', style: TextStyle(fontSize: 14, color: _kRed)),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: _kRed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    final items = [
      MenuEntry(icon: Icons.help_outline_rounded, label: 'Trung tâm hỗ trợ', type: 'web', route: AppConfig.urlSupport),
      MenuEntry(icon: Icons.privacy_tip_outlined, label: 'Chính sách bảo mật', type: 'web', route: AppConfig.urlPrivacy),
      MenuEntry(icon: Icons.description_outlined, label: 'Điều khoản dịch vụ', type: 'web', route: AppConfig.urlTerm),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kLightGray),
      ),
      child: Column(
        children: items.map((item) => _buildMenuItem(item)).toList(),
      ),
    );
  }

  Widget _buildLanguageCard() {
    final current = kLanguages.firstWhere((l) => l.code == _selectedLang);
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: _kLightGray),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: _showLanguageSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.language_rounded, size: 20, color: _kGray),
              const SizedBox(width: 14),
              Text('${current.flag} ${current.label}', style: const TextStyle(fontSize: 14, color: _kBlack)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kLightGray,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Text('Thay đổi', style: TextStyle(fontSize: 11, color: _kGray)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Image.asset(
            'lib/assets/images/zen-hone-circle-logo.png',
            height: 100,
          ),

          const Text(
            '${AppConfig.appName}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _kBlack),
          ),
          const SizedBox(height: 6),
          Text(
            'Đăng nhập để trải nghiệm dịch vụ',
            style: TextStyle(fontSize: 13, color: _kGray),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
    double? width,
    double? paddingVertical,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        color: filled ? ColorConfig.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: paddingVertical ?? 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: filled ? null : Border.all(color: ColorConfig.primary, width: .5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: filled ? Colors.white : ColorConfig.textPrimary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: filled ? Colors.white : _kBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}