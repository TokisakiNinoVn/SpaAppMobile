
import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';

// ==================== WIDGET TÁI SỬ DỤNG: HIỂN THỊ VÀ ĐỔI VAI TRÒ ====================

/// Widget hiển thị vai trò hiện tại và danh sách các vai trò có thể chuyển đổi.
/// Có thể dùng độc lập ở bất kỳ màn hình nào cần tính năng này.
class RoleSwitcherCard extends StatelessWidget {
  /// Danh sách các vai trò có sẵn (ví dụ: ['admin', 'ktv', 'customer'])
  final List<dynamic> roles;

  /// Vai trò đang hoạt động hiện tại
  final String activeRole;

  /// Hàm được gọi khi người dùng xác nhận chuyển sang vai trò mới.
  /// Widget sẽ tự hiển thị dialog xác nhận, sau đó gọi callback này.
  /// Bạn cần tự implement logic gọi API, lưu token, điều hướng, v.v.
  final Future<void> Function(String newRole) onSwitchRole;

  /// Trạng thái đang xử lý chuyển đổi (để vô hiệu hóa các nút)
  final bool isSwitching;

  /// Tùy chỉnh tiêu đề, màu sắc, v.v. (có thể mở rộng)
  final Color? primaryColor;
  final String? title;

  const RoleSwitcherCard({
    super.key,
    required this.roles,
    required this.activeRole,
    required this.onSwitchRole,
    this.isSwitching = false,
    this.primaryColor,
    this.title,
  });

  @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final primary = primaryColor ?? ColorConfig.primary;
  //
  //   // Lọc ra các vai trò khác với vai trò hiện tại
  //   final otherRoles = roles.where((role) => role != activeRole).toList();
  //
  //   if (roles.isEmpty) {
  //     return const SizedBox.shrink();
  //   }
  //
  //   return Container(
  //     width: double.infinity,
  //     margin: const EdgeInsets.only(bottom: 20),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: theme.cardColor,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: Colors.grey.shade200),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.04),
  //           blurRadius: 20,
  //           offset: const Offset(0, 8),
  //         ),
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.02),
  //           blurRadius: 6,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           title ?? "Vai trò hiện tại",
  //           style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
  //         ),
  //         const SizedBox(height: 10),
  //         _buildCurrentRoleCard(primary),
  //         if (otherRoles.isNotEmpty) ...[
  //           const SizedBox(height: 20),
  //           Text(
  //             "Chuyển vai trò",
  //             style: TextStyle(fontSize: 13, color: ColorConfig.textBlack),
  //           ),
  //           const SizedBox(height: 12),
  //           Wrap(
  //             spacing: 10,
  //             runSpacing: 10,
  //             children: otherRoles.map((role) {
  //               return _buildRoleChip(role, primary, context);
  //             }).toList(),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = primaryColor ?? ColorConfig.primary;

    if (roles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? "Chuyển vai trò",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: roles.map((role) {
              final isActive = role == activeRole;

              return _buildRoleChip(
                role: role,
                primary: primary,
                isActive: isActive,
                context: context,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRoleCard(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getRoleDisplayName(activeRole),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  // Widget _buildRoleChip(String role, Color primary, BuildContext context) {
  //   return InkWell(
  //     borderRadius: BorderRadius.circular(999),
  //     onTap: isSwitching ? null : () => _onRoleTap(role, context),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
  //       decoration: BoxDecoration(
  //         color: primary,
  //         borderRadius: BorderRadius.circular(999),
  //         border: Border.all(color: Colors.grey.shade200),
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             _getRoleDisplayName(role),
  //             style: TextStyle(
  //               fontWeight: FontWeight.bold,
  //               fontSize: 13,
  //               color: ColorConfig.textWhite,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildRoleChip({
    required String role,
    required Color primary,
    required bool isActive,
    required BuildContext context,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: (isSwitching || isActive)
              ? null
              : () => _onRoleTap(role, context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? primary.withOpacity(0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isActive
                    ? primary.withOpacity(0.35)
                    : Colors.grey.shade200,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: primary,
                  ),
                  const SizedBox(width: 6),
                ],

                Text(
                  _getRoleDisplayName(role),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isActive
                        ? primary
                        : ColorConfig.textBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onRoleTap(String newRole, BuildContext context) async {
    final confirmed = await _showConfirmationDialog(context, newRole);
    if (confirmed) {
      await onSwitchRole(newRole);
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String newRole) async {
    final displayName = _getRoleDisplayName(newRole);
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Xác nhận đổi vai trò",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Bạn có chắc muốn chuyển sang vai trò \"$displayName\"?\n"
              "Giao diện ứng dụng sẽ thay đổi tương ứng.",
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor ?? ColorConfig.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Chuyển ngay"),
          ),
        ],
      ),
    ) ??
        false;
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
}