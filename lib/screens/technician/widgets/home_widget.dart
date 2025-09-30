import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/format_helper.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final UserService userService = UserService();

  Map<String, dynamic>? technicianData;
  Map<String, dynamic>? inforLogin;
  bool isLoading = true;
  bool isUpdating = false;
  bool isTechnicianActive = false;
  bool isProfileActive = false;
  String role = '';
  String statusAccount = '';
  Map<String, dynamic>? userData;

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      SnackbarHelper.showError(context, "Bạn cần chờ hết thời gian đếm ngược để kiểm tra lại.");
      return;
    }

    try {
      final response = await userService.getIsAcceptHaveApprovalRequestService();
      if (response['success'] == true) {
        final data = response['data'];
        final isAccept = data['isAcceptHaveApprovalRequest'] == true;

        if (isAccept) {
          SnackbarHelper.showSuccess(context, "Tài khoản của bạn đã được phê duyệt, vui lòng đăng nhập lại");
          Future.delayed(const Duration(seconds: 2), () {
            context.go('/login');
          });
        } else {
          SnackbarHelper.showError(context, "Tài khoản của bạn chưa được phê duyệt, vui lòng liên hệ quản trị viên");
        }

        await prefs.setInt('lastCheckApproval', now);
        setState(() {
          _remainingSeconds = 10 * 60;
        });
        _startCountdown();
      }
    } catch (e) {
      SnackbarHelper.showError(context, "Lỗi kiểm tra tình trạng: $e");
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorConfig.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: technicianData?['avatar']['url'] != null
                            ? Image.network(
                          FormatHelper.formatImageUrl(technicianData!['avatar']['url']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset('lib/assets/images/avatar_placeholder.png'),
                        )
                            : Image.asset('lib/assets/images/avatar_placeholder.png'),
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
                              fontSize: 18,
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
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Toggle Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trạng thái hoạt động',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isTechnicianActive)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chế độ ${statusAccount == 'active' ? 'Online' : 'Offline'}',
                            style: const TextStyle(fontSize: 15),
                          ),
                          isUpdating
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Switch.adaptive(
                            value: statusAccount == 'active',
                            activeColor: ColorConfig.secondary,
                            onChanged: isProfileActive ? (_) => toggleUserStatus() : null,
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hồ sơ chưa được duyệt',
                            style: TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vui lòng chờ quản trị viên phê duyệt hồ sơ của bạn',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (technicianData != null) ...[
              if (isTechnicianActive) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await context.push('/user-edit-technician');
                      if (result == true) {
                        _loadUserDetail();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConfig.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa hồ sơ'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/home-technician/add-technician'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConfig.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: ColorConfig.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text('Thêm hồ sơ người quen'),
                      ],
                    ),
                  ),
                ),
              ],

              // Approval Section
              if (!isTechnicianActive) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tài khoản của bạn chưa được phê duyệt. Vui lòng liên hệ số điện thoại 0988788123 để được hỗ trợ.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _checkApprovalStatus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade50,
                                foregroundColor: Colors.orange.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.published_with_changes, size: 18),
                                  SizedBox(width: 8),
                                  Text("Kiểm tra tình trạng"),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              const phoneNumber = "0988788123";
                              Clipboard.setData(const ClipboardData(text: phoneNumber));
                              SnackbarHelper.showSuccess(context, 'Đã copy số điện thoại');
                            },
                            icon: Icon(Icons.copy, color: Colors.orange.shade700),
                            tooltip: 'Copy số điện thoại',
                          ),
                        ],
                      ),
                      if (_remainingSeconds > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            "Bạn có thể kiểm tra lại sau: ${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Widget _buildInfoRow(IconData icon, String label, String value) {
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Icon(icon, size: 20, color: Colors.grey.shade600),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               label,
  //               style: TextStyle(
  //                 fontSize: 13,
  //                 color: Colors.grey.shade600,
  //               ),
  //             ),
  //             const SizedBox(height: 4),
  //             Text(
  //               value,
  //               style: const TextStyle(
  //                 fontSize: 15,
  //                 color: Colors.black87,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }
}