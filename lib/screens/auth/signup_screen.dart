import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/app_config.dart';

import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import '../../config/color_config.dart';
import '../../models/Lang.dart';
import '../../storages/language_storage.dart';
import '../customer/tabs/components/LanguageSheet.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  String _selectedLang = 'vi';

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loadLang();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLang() async {
    final saved = await LanguageStorage.getLanguage();
    if (saved != null && mounted) setState(() => _selectedLang = saved);
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LanguageSheet(
        selected: _selectedLang,
        onSelect: (code) => setState(() => _selectedLang = code),
      ),
    );
  }

  Lang get _currentLang =>
      kLanguages.firstWhere((l) => l.code == _selectedLang);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F0),
      body: Stack(
        children: [
          // ── Decorative background blobs ─────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4B996).withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B7355).withOpacity(0.07),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // ── Top bar ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Close button
                          _CircleBtn(
                            icon: Icons.close_rounded,
                            onTap: () => context.go(
                                CustomerRouterConfig.homeCustomer),
                          ),

                          // Language switcher pill
                          _LangPill(
                            lang: _currentLang,
                            onTap: _showLanguageSheet,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),

                            // ── Logo ─────────────────────────────────────
                            _LogoBlock(),

                            const SizedBox(height: 36),

                            // ── Headline ──────────────────────────────────
                            _HeadlineBlock(),

                            const SizedBox(height: 40),

                            // ── Phone signup button ───────────────────────
                            _PrimaryButton(
                              // icon: Icons.phone_iphone_rounded,
                              label: 'Đăng ký bằng số điện thoại',
                              onTap: () => context.go('/register'),
                            ),

                            const SizedBox(height: 24),

                            // ── Divider ───────────────────────────────────
                            _OrDivider(),

                            const SizedBox(height: 24),

                            // ── Login redirect ────────────────────────────
                            _LoginRedirect(
                              onTap: () => context.go('/login-otp'),
                            ),

                            const SizedBox(height: 40),

                            // ── Terms note ────────────────────────────────
                            _TermsNote(),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Circle button (close) ────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF8B7355)),
      ),
    );
  }
}

// ─── Language pill button ──────────────────────────────────────────────────────
class _LangPill extends StatelessWidget {
  final Lang lang;
  final VoidCallback onTap;
  const _LangPill({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7355).withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF8B7355).withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              lang.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B7355),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: Color(0xFF8B7355)),
          ],
        ),
      ),
    );
  }
}

// ─── Logo block ────────────────────────────────────────────────────────────────
class _LogoBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo circle with gold ring
        // Container(
        //   padding: const EdgeInsets.all(4),
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     gradient: const LinearGradient(
        //       colors: [Color(0xFFD4B996), Color(0xFF8B7355)],
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //     ),
        //     boxShadow: [
        //       BoxShadow(
        //         color: const Color(0xFF8B7355).withOpacity(0.25),
        //         blurRadius: 24,
        //         offset: const Offset(0, 8),
        //       ),
        //     ],
        //   ),
        //   child: Container(
        //     width: 90,
        //     height: 90,
        //     decoration: const BoxDecoration(
        //       color: Colors.white,
        //       shape: BoxShape.circle,
        //     ),
        //     child: ClipOval(
        //       child: Padding(
        //         padding: const EdgeInsets.all(18),
        //         child: Image.asset(
        //           'lib/assets/images/zenhome-logo.png',
        //           fit: BoxFit.contain,
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
        const SizedBox(height: 16),

        // Brand name
        const Text(
          AppConfig.appNameUpperCase,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Color(0xFF8B7355),
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _goldDot(),
            const SizedBox(width: 6),
            const Text(
              'SPA & BEAUTY',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB0957A),
              ),
            ),
            const SizedBox(width: 6),
            _goldDot(),
          ],
        ),
      ],
    );
  }

  Widget _goldDot() => Container(
    width: 4,
    height: 4,
    decoration: const BoxDecoration(
      color: Color(0xFFD4B996),
      shape: BoxShape.circle,
    ),
  );
}

// ─── Headline block ────────────────────────────────────────────────────────────
class _HeadlineBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Tạo tài khoản',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3D2C1E),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Trải nghiệm dịch vụ chăm sóc sức khỏe\ncao cấp tại ${AppConfig.appName}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: const Color(0xFF3D2C1E).withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

// ─── Primary CTA button ────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  // final IconData? icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton(
      { required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF768C77), Color(0xFF768C77)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7355).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OR divider ────────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF8B7355).withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'hoặc',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF8B7355).withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B7355).withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Login redirect ────────────────────────────────────────────────────────────
class _LoginRedirect extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginRedirect({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFF8B7355).withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(
            //   Icons.login_rounded,
            //   color: const Color(0xFF8B7355),
            //   size: 20,
            // ),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(children: [
                const TextSpan(
                  text: 'Đã có tài khoản? ',
                  style: TextStyle(
                    color: Color(0xFF3D2C1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: 'Đăng nhập',
                  style: TextStyle(
                    color: ColorConfig.textBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Terms note ────────────────────────────────────────────────────────────────
class _TermsNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: 'Bằng cách đăng ký, bạn đồng ý với\n',
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF3D2C1E).withOpacity(0.4),
            height: 1.6,
          ),
        ),
        TextSpan(
          text: 'Điều khoản dịch vụ',
          style: TextStyle(
            fontSize: 12,
            color: ColorConfig.textBlack,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF8B7355),
          ),
        ),
        TextSpan(
          text: ' và ',
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF3D2C1E).withOpacity(0.4),
          ),
        ),
        TextSpan(
          text: 'Chính sách bảo mật',
          style: TextStyle(
            fontSize: 12,
            color: ColorConfig.textBlack,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF8B7355),
          ),
        ),
      ]),
      textAlign: TextAlign.center,
    );
  }
}