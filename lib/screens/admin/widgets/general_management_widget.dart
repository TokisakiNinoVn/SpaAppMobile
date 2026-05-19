import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';

// ─── Data Model ───────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String title;
  final String route;
  final Color color;
  final bool hasBadge;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.color,
    this.hasBadge = false,
  });
}

class _MenuGroup {
  final String label;
  final List<_MenuItem> items;

  const _MenuGroup({required this.label, required this.items});
}

// ─── Widget ───────────────────────────────────────────────────────
class GeneralManagementTab extends StatefulWidget {
  const GeneralManagementTab({super.key});

  @override
  State<GeneralManagementTab> createState() => _GeneralManagementTabState();
}

class _GeneralManagementTabState extends State<GeneralManagementTab>
    with SingleTickerProviderStateMixin {
  bool _isGridView = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Menu phân nhóm ──────────────────────────────────────────────
  static List<_MenuGroup> _groups = [
    _MenuGroup(
      label: 'Tài khoản & Tài chính',
      items: [
        _MenuItem(
          icon: Icons.person_outline_rounded,
          title: 'Quản lý tài khoản',
          route: AdminRouterConfig.technicianManagementAccount,
          color: const Color(0xFF6C63FF),
        ),
         _MenuItem(
          icon: Icons.account_balance_outlined,
          title: 'Quản lý ngân hàng',
          route: AdminRouterConfig.managementBank,
          color: Color(0xFF9B59B6),
        ),
        _MenuItem(
          icon: Icons.monetization_on,
          title: 'Cài đặt mức thu dịch vụ',
          route: AdminRouterConfig.managePlatformFees,
          color: Color(0xFFE1337C),
        ),
         _MenuItem(
          icon: Icons.outbond_outlined,
          title: 'Yêu cầu rút tiền',
          route: AdminRouterConfig.listWithdraw,
          color: Color(0xFFE74C3C),
          hasBadge: true,
        ),
      ],
    ),
     _MenuGroup(
      label: 'Dịch vụ & Ưu đãi',
      items: [
        _MenuItem(
          icon: Icons.menu_book_outlined,
          title: 'Quản lý dịch vụ, giá',
          route: AdminRouterConfig.managementService,
          color: Color(0xFFE91E8C),
        ),
        _MenuItem(
          icon: Icons.airplane_ticket_outlined,
          title: 'Voucher / Ưu đãi',
          route: AdminRouterConfig.managementDiscount,
          color: Color(0xFFF44336),
        ),
      ],
    ),
     _MenuGroup(
      label: 'Nội dung & Hiển thị',
      items: [
        _MenuItem(
          icon: Icons.image_outlined,
          title: 'Quản lý banner',
          route: AdminRouterConfig.managementBanner,
          color: Color(0xFF27AE60),
        ),
        _MenuItem(
          icon: Icons.tune_rounded,
          title: 'Cài đặt hiển thị dịch vụ nổi bật',
          route: AdminRouterConfig.listFeatureService,
          color: Color(0xFF7C4DFF),
        ),
      ],
    ),
     _MenuGroup(
      label: 'Thông báo & Thống kê',
      items: [
        _MenuItem(
          icon: Icons.notifications_outlined,
          title: 'Thông báo hệ thống',
          route: AdminRouterConfig.notificationManagement,
          color: Color(0xFFE67E22),
          hasBadge: true,
        ),
        _MenuItem(
          icon: Icons.bar_chart_rounded,
          title: 'Thống kê',
          route: AdminRouterConfig.statistical,
          color: Color(0xFF2E7D32),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleViewMode() {
    setState(() => _isGridView = !_isGridView);
    _animController.forward(from: 0);
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    letterSpacing: .6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Quản lý chung',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          _ViewToggle(
            isGridView: _isGridView,
            onToggle: _toggleViewMode,
          ),
        ],
      ),
    );
  }

  // ── Section label ───────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8, top: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          letterSpacing: .9,
        ),
      ),
    );
  }

  // ── List item ───────────────────────────────────────────────────
  Widget _buildListItem(_MenuItem item) {
    final bgColor = item.color.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(item.route),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEAEAEA),
                width: .8,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 20,
                      ),
                    ),

                    if (item.hasBadge)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4D4D),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // Title
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Grid item ───────────────────────────────────────────────────
  Widget _buildGridItem(_MenuItem item) {
    final bgColor = item.color.withOpacity(0.1);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(item.route),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAEAEA), width: .8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  if (item.hasBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D4D),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── List view ───────────────────────────────────────────────────
  Widget _buildListView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: _groups.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(group.label),
            ...group.items.map(_buildListItem),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  // ── Grid view ───────────────────────────────────────────────────
  Widget _buildGridView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: _groups.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(group.label),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: group.items.map(_buildGridItem).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 1),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _isGridView ? _buildGridView() : _buildListView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Toggle Button Component ─────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final bool isGridView;
  final VoidCallback onToggle;

  const _ViewToggle({required this.isGridView, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF6C63FF);
    const activeBg = Color(0xFF6C63FF);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.view_list_rounded,
            label: 'List',
            isActive: !isGridView,
            activeBg: activeBg,
            onTap: !isGridView ? null : onToggle,
          ),
          _ToggleBtn(
            icon: Icons.grid_view_rounded,
            label: 'Grid',
            isActive: isGridView,
            activeBg: activeBg,
            onTap: isGridView ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeBg;
  final VoidCallback? onTap;

  const _ToggleBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}