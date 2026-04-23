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

  // Mock active order data - replace with real data from API
  final Map<String, dynamic>? _activeOrder = {
    'id': 'ORD-12345',
    'serviceName': 'Massage Thư Giãn Cao Cấp',
    'customerName': 'Nguyễn Thị Hương',
    'address': '123 Đường Láng, Đống Đa, Hà Nội',
    'price': 450000,
    'status': 'Đang thực hiện',
    'time': '14:30 - 16:00',
  };

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

  bool get _isOnline =>
      isTechnicianActive && isProfileActive && statusAccount == 'active';

  void _navigateToNotifications() {
    // Navigate to notifications screen - replace with your actual route
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBar(
              title: Text('Thông báo'),
              centerTitle: true,
              elevation: 0,
            ),
          ),
          body: const Center(
            child: Text(
              'Danh sách thông báo sẽ hiển thị ở đây',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
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
            // Header row with avatar, info and notification icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with green border when online
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isOnline ? Colors.green : Colors.grey.shade300,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                          Image.asset('lib/assets/images/avatar_placeholder.png'),
                    )
                        : Image.asset(
                      'lib/assets/images/avatar_placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
                      Text(
                        inforLogin?['phone'] ?? 'Không rõ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Notification icon with red dot badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: _navigateToNotifications,
                      icon: const Icon(Icons.notifications_outlined, size: 28),
                      color: Colors.grey.shade700,
                      tooltip: 'Thông báo',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // const SizedBox(height: 8),

            // Status toggle & location update - simplified row
            if (isTechnicianActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        const Text(
                          'Trạng thái',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        isUpdating
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Tooltip(
                          message: 'Bật/tắt nhận việc',
                          child: Switch(
                            value: statusAccount == 'active',
                            activeColor: ColorConfig.secondary,
                            activeTrackColor: ColorConfig.secondary.withOpacity(0.3),
                            inactiveThumbColor: Colors.grey.shade400,
                            inactiveTrackColor: Colors.grey.shade300,
                            onChanged: isProfileActive ? (_) => toggleUserStatus() : null,
                          ),
                        ),
                      ],
                    ),
                    Tooltip(
                      message: 'Cập nhật vị trí hiện tại',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: IconButton(
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
                              : const Icon(Icons.my_location, size: 20, color: Colors.blue),
                          padding: const EdgeInsets.all(10),
                          splashRadius: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Order status card (mock or empty)
              _buildOrderCard(),
            ] else ...[
              // Inactive profile warning
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hồ sơ chưa được duyệt. Vui lòng liên hệ quản trị viên.',
                        style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
                      ),
                    ),
                    TextButton(
                      onPressed: _checkApprovalStatus,
                      child: const Text('Kiểm tra'),
                    ),
                  ],
                ),
              ),
              if (_remainingSeconds > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    "Kiểm tra lại sau: ${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 24),

            ],

          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard() {
    if (_activeOrder != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bookmark_border_outlined, size: 18, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'ĐƠN ĐANG THỰC HIỆN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _activeOrder!['status'],
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.spa, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        _activeOrder!['serviceName'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text('Khách hàng: ${_activeOrder!['customerName']}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_activeOrder!['address'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text(_activeOrder!['time'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(
                        '${FormatHelper.formatPrice(_activeOrder!['price'])}đ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        SnackBarHelper.showWarning(context, 'Chức năng đang được phát triển');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConfig.secondary.withOpacity(.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: const Text('Xem chi tiết >> '),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        SnackBarHelper.showWarning(context, 'Chức năng đang được phát triển');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConfig.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: const Text('Xác nhận hoàn thành'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Bạn đang không thực hiện đơn nào',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              'Đơn hàng mới sẽ xuất hiện tại đây',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
  }
}