import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';

class SwitchRoleWidget extends StatelessWidget {
  final String? rolesActive;
  final List roles;

  const SwitchRoleWidget({
    super.key,
    required this.roles,
    required this.rolesActive,
  });

  static const Map<String, Map<String, dynamic>> roleConfig = {
    'admin': {
      'label': 'Quản trị viên',
      'icon': Icons.admin_panel_settings_rounded,
    },
    'quanly': {
      'label': 'Quản lý',
      'icon': Icons.manage_accounts_rounded,
    },
    'ktv': {
      'label': 'Kỹ thuật viên',
      'icon': Icons.build_circle_rounded,
    },
    'customer': {
      'label': 'Khách hàng',
      'icon': Icons.person_rounded,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Role hiện tại
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorConfig.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ColorConfig.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: ColorConfig.primary.withOpacity(0.12),
                  child: Icon(
                    roleConfig[rolesActive]?['icon'] ??
                        Icons.person_rounded,
                    color: ColorConfig.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vai trò hiện tại',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        roleConfig[rolesActive]?['label'] ??
                            'Không xác định',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Danh sách vai trò',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: roles.map((role) {
              final bool isActive = role == rolesActive;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? ColorConfig.primary
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? ColorConfig.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      roleConfig[role]?['icon'] ??
                          Icons.person_outline_rounded,
                      size: 18,
                      color: isActive
                          ? Colors.white
                          : Colors.black87,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      roleConfig[role]?['label'] ?? role,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class AppConfig {
  static const List adminPhone = ['0123456789', '0777378727'];
}