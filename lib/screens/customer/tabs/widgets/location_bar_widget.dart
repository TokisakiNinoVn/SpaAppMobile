import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/utils/address_util.dart';

class LocationBarWidget extends StatelessWidget {
  // final bool isDark;
  final bool checkPermissionLocation;
  final String? locationText;
  final bool locationLoading;
  final int locationCooldownSeconds;
  final VoidCallback onLocationTap;
  final String Function(int) formatCooldown;

  const LocationBarWidget({
    super.key,
    // required this.isDark,
    required this.checkPermissionLocation,
    required this.locationText,
    required this.locationLoading,
    required this.locationCooldownSeconds,
    required this.onLocationTap,
    required this.formatCooldown,
  });

  @override
  Widget build(BuildContext context) {
    final bool inCooldown =
        checkPermissionLocation && locationCooldownSeconds > 0;
    final bool canUpdate =
        checkPermissionLocation && locationCooldownSeconds == 0;

    final String buttonLabel = !checkPermissionLocation
        ? 'Cập nhật'
        : inCooldown
        ? formatCooldown(locationCooldownSeconds)
        : 'Cập nhật';

    final List<Color> buttonGradient = inCooldown
        ? [Colors.grey.shade500, Colors.grey.shade600]
        : [const Color(0xFF43A047), const Color(0xFF00897B)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: locationLoading ? null : onLocationTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: locationText != null
                ? ColorConfig.white : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: locationText != null
                  ? const Color(0xFF4CAF50).withOpacity(0.5)
                  : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: locationLoading
                    ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4CAF50),
                  ),
                )
                    : Icon(
                  checkPermissionLocation
                      ? Icons.location_on
                      : Icons.location_off_outlined,
                  key: ValueKey(checkPermissionLocation),
                  size: 20,
                  color: locationText != null
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[500],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  checkPermissionLocation
                      ? (locationText != null
                      ? 'Vị trí bạn: ${AddressUtil.formatAddressProvince(locationText!)}'
                      : 'Đang xác định vị trí...')
                      : 'Nhấn để cấp quyền vị trí',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: locationText != null
                        ? FontWeight.w600
                        : FontWeight.bold,
                    color: locationText != null
                        ? Colors.green[300] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Nút hành động
              GestureDetector(
                onTap: locationLoading || inCooldown ? null : onLocationTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: buttonGradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}