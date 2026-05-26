
import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/extensions/login_type_role_extension.dart';


class RoleSwitcherCard extends StatelessWidget {
  final List<dynamic> roles;

  final String activeRole;
  final Future<void> Function(String newRole) onSwitchRole;

  final bool isSwitching;
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = primaryColor ?? ColorConfig.primary;

    if (roles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
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

  Widget _buildRoleChip({
    required String role,
    required Color primary,
    required bool isActive,
    required BuildContext context,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Tooltip(
        message: _getRoleDisplayName(role),
        waitDuration: const Duration(milliseconds: 400),
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
                      ? primary.withOpacity(0.5)
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
                    _getRoleShortDisplayName(role),
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
    final displayShortName = _getRoleShortDisplayName(newRole);
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
    return LoginTypeRoleExtension
        .fromValue(roleKey)
        .displayName;
  }

  String _getRoleShortDisplayName(String roleKey) {
    return LoginTypeRoleExtension
        .fromValue(roleKey)
        .shortDisplay;
  }
}