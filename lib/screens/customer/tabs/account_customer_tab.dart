import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/helper/shared_preferences_helper.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spa_app/screens/customer/tabs/widgets/GoldIconButton.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/services/user_service.dart';

import '../../../helper/check_login_helper.dart';
import '../../../storages/language_storage.dart';
import './widgets/SpaDialog.dart';
import './widgets/MenuEntry.dart';
import '../../../models/Lang.dart';
import './widgets/LanguageSheet.dart';

const _kGold       = Color(0xFF8B7355);
const _kGoldLight  = Color(0xFFD4B996);
const _kCream      = Color(0xFFF9F5F0);
const _kCard       = Colors.white;
const _kRed        = Color(0xFFD94040);

// ─── Main widget ──────────────────────────────────────────────────────────────
class AccountCustomerTab extends StatefulWidget {
  const AccountCustomerTab({super.key});

  @override
  State<AccountCustomerTab> createState() => _AccountCustomerTabState();
}

class _AccountCustomerTabState extends State<AccountCustomerTab>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();

  bool _isSwitchingRole = false;
  bool _isLogin         = false;
  Map<String, dynamic>? inforUser;
  String _selectedLang  = 'vi';

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _checkLogin();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();
    if (loggedIn) await _loadInforUser();
    if (!mounted) return;
    setState(() => _isLogin = loggedIn);
    _fadeCtrl.forward();
  }

  Future<void> _loadInforUser() async {
    try {
      final prefs      = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('inforUserLogin');
      final data       = jsonString != null
          ? jsonDecode(jsonString) as Map<String, dynamic>
          : null;
      if (!mounted) return;
      setState(() => inforUser = data);
    } catch (e) {
      debugPrint('❌ Lỗi parse: $e');
      if (!mounted) return;
      setState(() => inforUser = null);
    }
  }

  // ── actions ───────────────────────────────────────────────────────────────
  Future<void> _changeRole() async {
    setState(() => _isSwitchingRole = true);
    try {
      final response = await _userService.changeRoleService({});
      if (!mounted) return;
      if (response['success'] == true) {
        _showSnack("Đã chuyển đổi vai trò thành công. Vui lòng đăng nhập lại!", Colors.green);
        await SharedPreferencesHelper.logOut();
        context.go(CustomerRouterConfig.homeCustomer);
      } else {
        _showSnack("Có lỗi xảy ra khi chuyển đổi vai trò", _kRed);
      }
    } catch (e) {
      if (mounted) _showSnack("Lỗi: $e", _kRed);
    } finally {
      if (mounted) setState(() => _isSwitchingRole = false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── dialogs ───────────────────────────────────────────────────────────────
  void _showRoleSwitchDialog() {
    showDialog(
      context: context,
      builder: (_) => SpaDialog(
        icon: Icons.switch_account_rounded,
        title: 'Chuyển đổi vai trò',
        body:
        'Bạn muốn chuyển sang vai trò kỹ thuật viên?\nSau khi chuyển đổi, bạn cần đăng nhập lại.',
        cancelLabel: 'Hủy',
        confirmLabel: 'Chuyển đổi',
        confirmColor: _kGold,
        onConfirm: _changeRole,
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => SpaDialog(
        icon: Icons.logout_rounded,
        iconColor: _kRed,
        title: 'Đăng xuất',
        body: 'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',
        cancelLabel: 'Hủy',
        confirmLabel: 'Đăng xuất',
        confirmColor: _kRed,
        onConfirm: () {
          // Không cần làm gì ở đây vì dialog đã pop với kết quả true
        },
      ),
    );

    if (result == true && mounted) {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await SharedPreferencesHelper.logOut();

        // Đóng loading dialog
        if (mounted) Navigator.of(context).pop();

        // Xóa toàn bộ stack và điều hướng về login
        if (mounted) {
          // Đợi frame tiếp theo để đảm bảo mọi thứ ổn định
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Sử dụng pushReplacement để thay thế toàn bộ stack
              context.pushReplacement(CustomerRouterConfig.homeCustomer);
            }
          });
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showSnack("Lỗi đăng xuất: $e", _kRed);
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

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Column(children: [
                  if (_isLogin) ...[
                    const SizedBox(height: 14),

                    _buildUserCard(),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Tài khoản của tôi',
                      icon: Icons.manage_accounts_rounded,
                      items: [
                        MenuEntry(
                          icon: Icons.person_outline_rounded,
                          label: 'Thông tin cá nhân',
                          route: CustomerRouterConfig.updateProfile,
                        ),
                        MenuEntry(
                          icon: Icons.favorite_border_rounded,
                          label: 'Kỹ thuật viên yêu thích',
                          route: CustomerRouterConfig.listLike,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Auth buttons
                  if (_isLogin) ...[
                    _buildActionButton(
                      label: 'Đăng xuất',
                      icon: Icons.logout_rounded,
                      color: _kRed,
                      onTap: _showLogoutDialog,
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildGuestBanner(),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      label: 'Đăng nhập',
                      icon: Icons.login_rounded,
                      color: _kGold,
                      filled: true,
                      onTap: () => context.go(GlobalRouterConfig.loginOTP),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Đăng ký tài khoản',
                      icon: Icons.person_add_alt_1_rounded,
                      color: _kGold,
                      onTap: () => context.go(GlobalRouterConfig.register),
                    ),
                  ],
                  const SizedBox(height: 28),
                  // Language picker card
                  _buildLanguageCard(),
                  const SizedBox(height: 28),
                  // Support section
                  _buildSection(
                    title: 'Hỗ trợ',
                    icon: Icons.support_agent_rounded,
                    items: [
                      MenuEntry(
                        icon: Icons.help_outline_rounded,
                        label: 'Trung tâm hỗ trợ',
                        type: 'web',
                        route: AppConfig.urlSupport,
                      ),
                      MenuEntry(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Chính sách bảo mật',
                        type: 'web',
                        route: AppConfig.urlPrivacy,
                      ),
                      MenuEntry(
                        icon: Icons.description_outlined,
                        label: 'Điều khoản dịch vụ',
                        type: 'web',
                        route: AppConfig.urlTerm,
                      ),
                    ],
                  ),


                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── sub-widgets ───────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      elevation: 0,
      backgroundColor: _kCream,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: Row(
          children: [
            Container(
              width: 4, height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kGoldLight, _kGold],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Tài khoản',
              style: TextStyle(
                color: _kGold,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        background: Container(color: _kCream),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kGold.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [

          // Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGoldLight, _kGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kGold.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('lib/assets/images/img_3.png'),
              backgroundColor: Color(0xFFF0E8DC),
            ),
          ),

          const SizedBox(width: 8),


          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inforUser?['fullName'] ?? inforUser?['phone'] ?? '—',
                  style: const TextStyle(
                    color: Color(0xFF3D2C1E),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (inforUser?['phone'] != null &&
                    inforUser?['fullName'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      inforUser!['phone'],
                      style: const TextStyle(
                        color: _kGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Khách hàng',
                    style: TextStyle(
                      color: _kGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Switch role button
          _isSwitchingRole
              ? const SizedBox(
            width: 44, height: 44,
            child: Center(
              child: CircularProgressIndicator(
                  color: _kGold, strokeWidth: 2.5),
            ),
          )
              : GoldIconButton(
            icon: Icons.change_circle_rounded,
            onTap: _showRoleSwitchDialog,
            tooltip: 'Chuyển vai trò',
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<MenuEntry> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              children: [
                Icon(icon, color: _kGoldLight, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kGold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: _kGold.withOpacity(0.1), height: 12),
          ),

          // Items
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return _buildTile(e.value, isLast: isLast);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTile(MenuEntry entry, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, isLast ? 0 : 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (entry.type == 'web') {
            launchUrl(Uri.parse(entry.route));
          } else if (entry.route.isNotEmpty) {
            context.go(entry.route);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _kGold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, color: _kGold, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3D2C1E),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _kGold.withOpacity(0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard() {
    final current =
    kLanguages.firstWhere((l) => l.code == _selectedLang);
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              children: [
                const Icon(Icons.translate_rounded,
                    color: _kGoldLight, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'NGÔN NGỮ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kGold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: _kGold.withOpacity(0.1), height: 12),
          ),
          InkWell(
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24)),
            onTap: _showLanguageSheet,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _kGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.language_rounded,
                        color: _kGold, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${current.flag}  ${current.label}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3D2C1E),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kGoldLight, _kGold],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Thay đổi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kGold.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset('lib/assets/images/spa_logo.png', height: 80),
          const SizedBox(height: 14),
          const Text(
            'Chào mừng đến với',
            style: TextStyle(
              color: Color(0xFFB0957A),
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const Text(
            'Serene Spa',
            style: TextStyle(
              color: _kGold,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đăng nhập để trải nghiệm dịch vụ\nchăm sóc sức khỏe cao cấp',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF3D2C1E).withOpacity(0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: filled
                  ? null
                  : Border.all(color: color, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: filled ? Colors.white : color, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: filled ? Colors.white : color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
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
