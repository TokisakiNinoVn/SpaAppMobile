import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/helper/format_helper.dart';

import '../../../helper/location_helper.dart';

class HomeTechnicianTab extends StatefulWidget {
  const HomeTechnicianTab({super.key});

  @override
  State<HomeTechnicianTab> createState() => _HomeTechnicianTabState();
}

class _HomeTechnicianTabState extends State<HomeTechnicianTab> {
  final UserService userService = UserService();
  final TechnicianService technicianService = TechnicianService();

  Map<String, dynamic>? technicianData;
  List<dynamic>? inforService;
  Map<String, dynamic>? inforLogin;
  bool isLoading = true;
  bool isUpdating = false;
  bool isUpdatingLocation = false;
  bool checkPermission = false;
  bool isTechnicianActive = false;
  bool isProfileActive = false;
  String role = '';
  String statusAccount = '';
  Map<String, dynamic>? userData;
  double? currentLat;
  double? currentLng;

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
    loadServiceInfor();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final location = await LocationHelper.getCurrentLocation();
    if (location != null) {
      setState(() {
        currentLat = location.latitude;
        currentLng = location.longitude;
      });
    }
  }

  Future<void> _updateLocation() async {
    if (currentLat == null || currentLng == null) {
      SnackBarHelper.showError(context, "Không thể lấy vị trí hiện tại");
      return;
    }

    setState(() {
      isUpdatingLocation = true;
    });

    try {
      final data = {
        "lat": currentLat,
        "lng": currentLng,
      };

      final response = await technicianService.updateLocationTechnicianService(data);

      if (response['success'] == true) {
        SnackBarHelper.showSuccess(context, "Cập nhật vị trí thành công");
      } else {
        SnackBarHelper.showError(context, response['message'] ?? "Cập nhật vị trí thất bại");
      }
    } catch (e) {
      SnackBarHelper.showError(context, "Lỗi cập nhật vị trí: $e");
    } finally {
      setState(() {
        isUpdatingLocation = false;
      });
    }
  }

  Future<void> _checkApprovalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('lastCheckApproval') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastCheck < 10 * 60 * 1000) {
      final remaining = 10 * 60 * 1000 - (now - lastCheck);
      setState(() {
        _remainingSeconds = (remaining / 1000).ceil();
      });
      SnackBarHelper.showError(context, "Bạn cần chờ hết thời gian đếm ngược để kiểm tra lại.");
      return;
    }

    try {
      final response = await userService.getIsAcceptHaveApprovalRequestService();
      if (response['success'] == true) {
        final data = response['data'];
        final isAccept = data['isAcceptHaveApprovalRequest'] == true;

        if (isAccept) {
          SnackBarHelper.showSuccess(context, "Tài khoản của bạn đã được phê duyệt, vui lòng đăng nhập lại");
          Future.delayed(const Duration(seconds: 2), () {
            context.go('/login');
          });
        } else {
          SnackBarHelper.showError(context, "Tài khoản của bạn chưa được phê duyệt, vui lòng liên hệ quản trị viên");
        }

        await prefs.setInt('lastCheckApproval', now);
        setState(() {
          _remainingSeconds = 10 * 60;
        });
        _startCountdown();
      }
    } catch (e) {
      SnackBarHelper.showError(context, "Lỗi kiểm tra tình trạng: $e");
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _loadUserDetail() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString('role') ?? 'ktv';
    inforLogin = jsonDecode(prefs.getString('inforUserLogin') ?? '{}');
    isTechnicianActive = prefs.getString('isTechnicianActive') == 'true';
    isProfileActive = prefs.getString('isTechnicianActive') == 'true';
    statusAccount = prefs.getString('statusAccount') ?? 'inactive';

    try {
      final response = await userService.loadDetailUserService();
      if (response['success'] == true) {
        setState(() {
          userData = response['data'];
          technicianData = userData?['technician'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Lỗi load thông tin chi tiết người dùng: $e");
    }
  }

  Future<void> loadServiceInfor() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('inforService');

    if (jsonString != null) {
      inforService = jsonDecode(jsonString);
    } else {
      inforService = null;
    }
  }

  Future<void> loadPermissionLocation() async {
    checkPermission = await LocationHelper.isLocationReady();
  }

  Future<void> toggleUserStatus() async {
    if (technicianData == null || !isTechnicianActive) return;

    final newStatus = statusAccount == 'active' ? 'inactive' : 'active';

    setState(() => isUpdating = true);
    final response = await userService.changeStatusUserService({
      'status': newStatus,
    });

    if (response['success'] == true) {
      setState(() {
        statusAccount = response['data']['status'];
        technicianData!['status'] = statusAccount;
        isUpdating = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('technician', jsonEncode(technicianData));
      await prefs.setString('statusAccount', response['data']['status']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chuyển sang trạng thái: ${newStatus == 'inactive' ? 'Offline' : 'Online'}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thay đổi thất bại: ${response['message'] ?? 'Lỗi không xác định'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText() {
    if (!isTechnicianActive) return 'Hồ sơ chưa được duyệt';
    if (!isProfileActive) return 'Hồ sơ tạm ngừng hoạt động';
    return statusAccount == 'active' ? 'Online' : 'Offline';
  }

  Color _getStatusColor() {
    if (!isTechnicianActive) return Colors.orange;
    if (!isProfileActive) return Colors.grey;
    return statusAccount == 'active' ? Colors.green : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadUserDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorConfig.secondary.withOpacity(0.4),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: technicianData?['avatar']['url'] != null
                        ? Image.network(
                      FormatHelper.formatNetworkImageUrl(
                          technicianData!['avatar']['url']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(
                              'lib/assets/images/avatar_placeholder.png'),
                    )
                        : Image.asset(
                      'lib/assets/images/avatar_placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        technicianData?['fullName'] ?? 'Không có tên',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        inforLogin?['phone'] ?? 'Không rõ',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor().withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusAccount == 'active'
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              size: 12,
                              color: _getStatusColor(),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ==================== TRẠNG THÁI HOẠT ĐỘNG ====================
            const Text(
              'Trạng thái hoạt động',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: isTechnicianActive
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chế độ ${statusAccount == 'active' ? 'Online' : 'Offline'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusAccount == 'active'
                            ? 'Bạn đang sẵn sàng nhận việc'
                            : 'Bạn đang không nhận việc mới',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  isUpdating
                      ? const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                        strokeWidth: 3),
                  )
                      : Switch.adaptive(
                    value: statusAccount == 'active',
                    activeColor: ColorConfig.secondary,
                    activeTrackColor:
                    ColorConfig.secondary.withOpacity(0.3),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: isProfileActive
                        ? (_) => toggleUserStatus()
                        : null,
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hồ sơ chưa được duyệt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng chờ quản trị viên phê duyệt hồ sơ của bạn.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ==================== CÁC NÚT HÀNH ĐỘNG ====================
            if (technicianData != null) ...[
              if (isTechnicianActive) ...[
                // Row cho 2 nút Sửa hồ sơ và Sửa dịch vụ
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result =
                          await context.push('/user-edit-technician');
                          if (result == true) {
                            _loadUserDetail();
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text(
                          'Sửa hồ sơ',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConfig.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.go("/home-technician/technician-update-service");
                        },
                        icon: const Icon(Icons.handyman_outlined, size: 20),
                        label: const Text(
                          'Sửa dịch vụ',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConfig.secondary,
                          side: BorderSide(color: ColorConfig.secondary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Nút cập nhật vị trí
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isUpdatingLocation ? null : () async {
                      await _getCurrentLocation();
                      await _updateLocation();
                    },
                    icon: isUpdatingLocation
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.location_on_outlined, size: 20),
                    label: Text(
                      isUpdatingLocation ? 'Đang cập nhật...' : 'Cập nhật vị trí',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],

              // ==================== PHẦN CHƯA ĐƯỢC DUYỆT ====================
              if (!isTechnicianActive) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tài khoản của bạn chưa được phê duyệt.\nVui lòng liên hệ hỗ trợ để được xét duyệt nhanh hơn.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.orange.shade800,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _checkApprovalStatus,
                              icon: const Icon(
                                  Icons.published_with_changes_outlined,
                                  size: 18),
                              label: const Text('Kiểm tra tình trạng'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              const phoneNumber = "0988788123";
                              Clipboard.setData(
                                  const ClipboardData(text: phoneNumber));
                              SnackBarHelper.showSuccess(
                                  context, 'Đã copy số điện thoại');
                            },
                            icon: Icon(Icons.copy_rounded,
                                color: Colors.orange.shade700),
                            tooltip: 'Copy số điện thoại',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.orange.shade50,
                            ),
                          ),
                        ],
                      ),
                      if (_remainingSeconds > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            "Kiểm tra lại sau: ${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}