import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/shared_preferences_helper.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/order_provider.dart';
import 'package:spa_app/routes/config/technician_router_config.dart';
import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/helper/format_helper.dart';

import '../../../helper/location_helper.dart';
import '../../../storage/index.dart';

class HomeTechnicianTab extends StatefulWidget {
  const HomeTechnicianTab({super.key});

  @override
  State<HomeTechnicianTab> createState() => _HomeTechnicianTabState();
}

class _HomeTechnicianTabState extends State<HomeTechnicianTab> {
  final UserService userService = UserService();
  final TechnicianService technicianService = TechnicianService();
  final OrderService _orderService = OrderService();

  Map<String, dynamic>? technicianData;
  // List<dynamic>? inforService;
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
  String _errorMessage = '';
  double? currentLat;
  double? currentLng;

  bool isWorking = false;
  String idOrderWorking = "";

  // Sử dụng late với nullable thay vì final để có thể gán lại
  String? acceptedAt;
  Map<String, dynamic>? orderDetail;

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
    // loadServiceInfor();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCheckWorkingOrder();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Future<void> _getCurrentLocation(BuildContext context) async {
  //   try {
  //     // 1. Kiểm tra permission
  //     LocationPermission permission =
  //     await Geolocator.checkPermission();
  //
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //     }
  //
  //     // Chỉ hiện popup custom khi bị từ chối vĩnh viễn
  //     if (permission == LocationPermission.deniedForever) {
  //       await _showEnableGPSSettingsDialog();
  //       return;
  //     }
  //
  //     if (permission != LocationPermission.whileInUse &&
  //         permission != LocationPermission.always) {
  //       SnackBarHelper.showError(
  //         context,
  //         "Không có quyền truy cập vị trí",
  //       );
  //       return;
  //     }
  //
  //     // 2. Kiểm tra GPS
  //     bool serviceEnabled =
  //     await Geolocator.isLocationServiceEnabled();
  //
  //     if (!serviceEnabled) {
  //       await Geolocator.openLocationSettings();
  //       return;
  //     }
  //
  //     // 3. Yêu cầu vị trí thật
  //     // Đây là chỗ Google Play Services có thể tự hiện
  //     // popup Location Accuracy như ảnh bạn gửi
  //     final location = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );
  //
  //     setState(() {
  //       currentLat = location.latitude;
  //       currentLng = location.longitude;
  //     });
  //   } catch (e) {
  //     SnackBarHelper.showError(
  //       context,
  //       "Không thể lấy vị trí hiện tại: $e",
  //     );
  //   }
  // }

  /// ====================== CẬP NHẬT VỊ TRÍ ======================
  Future<void> _getCurrentLocation(BuildContext context) async {
    setState(() => isUpdatingLocation = true);

    try {
      // 1. Kiểm tra và yêu cầu quyền
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await _showEnableGPSSettingsDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        SnackBarHelper.showError(context, "Bạn đã từ chối quyền truy cập vị trí");
        return;
      }

      // 2. Lấy vị trí với độ chính xác cao
      //    → Google Play Services sẽ tự động hiện popup "Location Accuracy"
      //      nếu cần thiết ("For a better experience...")
      final Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,     // Quan trọng: dùng high để trigger Location Accuracy
        timeLimit: const Duration(seconds: 20),
      );

      setState(() {
        currentLat = location.latitude;
        currentLng = location.longitude;
      });

      // Cập nhật lên server
      await _updateLocation();

    } on LocationServiceDisabledException {
      // Trường hợp GPS bị tắt hoàn toàn
      final shouldOpenSettings = await _showEnableGPSDialog();
      if (shouldOpenSettings == true) {
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      SnackBarHelper.showError(
        context,
        "Không thể lấy vị trí hiện tại.\nLỗi: ${e.toString()}",
      );
    } finally {
      setState(() => isUpdatingLocation = false);
    }
  }

  /// Dialog khi GPS bị tắt
  Future<bool?> _showEnableGPSDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.red),
              SizedBox(width: 12),
              Text('Vị trí đang tắt'),
            ],
          ),
          content: const Text(
            'Để cập nhật vị trí chính xác, vui lòng bật Dịch vụ vị trí (GPS).\n\n'
                'Hệ thống sẽ hiển thị popup của Google Play Services để cải thiện độ chính xác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bật GPS'),
            ),
          ],
        );
      },
    );
  }

  // Thêm method mới:
  // Future<bool?> _showEnableGPSSettingsDialog() async {
  //   return showDialog<bool>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         title: const Row(
  //           children: [
  //             Icon(Icons.location_off_outlined),
  //             SizedBox(width: 8),
  //             Expanded(
  //               child: Text('Dịch vụ vị trí đang tắt'),
  //             ),
  //           ],
  //         ),
  //         content: const Text(
  //           'Ứng dụng cần quyền truy cập vị trí để cập nhật vị trí hiện tại của bạn. '
  //               'Vui lòng bật Dịch vụ vị trí trong phần Cài đặt để tiếp tục.',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(false),
  //             child: const Text('Để sau'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () => Navigator.of(context).pop(true),
  //             child: const Text('Mở Cài đặt'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  /// Dialog khi bị deniedForever
  Future<bool?> _showEnableGPSSettingsDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Cho phép truy cập vị trí'),
        content: const Text(
          'Để sử dụng tính năng này, ứng dụng cần quyền truy cập vị trí của bạn. '
              'Bạn đã tắt quyền này trước đó. Vui lòng mở Cài đặt để cấp quyền vị trí cho ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              Geolocator.openAppSettings();
            },

            style: ButtonStyle(
              // foregroundBuilder: Colors.green
            ),

            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  // Future<void> _updateLocation() async {
  //   // if (currentLat == null || currentLng == null) {
  //   //   SnackBarHelper.showError(context, "Không thể lấy vị trí hiện tại");
  //   //   return;
  //   // }
  //
  //   setState(() => isUpdatingLocation = true);
  //
  //   try {
  //     final data = {"lat": currentLat, "lng": currentLng};
  //     final response = await technicianService.updateLocationTechnicianService(data);
  //
  //     if (response['success'] == true) {
  //       SnackBarHelper.showSuccess(context, "Cập nhật vị trí thành công");
  //     } else {
  //       SnackBarHelper.showError(context, response['message'] ?? "Cập nhật vị trí thất bại");
  //     }
  //   } catch (e) {
  //     SnackBarHelper.showError(context, "Lỗi cập nhật vị trí: $e");
  //   } finally {
  //     setState(() => isUpdatingLocation = false);
  //   }
  // }

  /// Cập nhật vị trí lên server
  Future<void> _updateLocation() async {
    if (currentLat == null || currentLng == null) return;

    try {
      final data = {"lat": currentLat, "lng": currentLng};
      final response = await technicianService.updateLocationTechnicianService(data);

      if (response['success'] == true) {
        SnackBarHelper.showSuccess(context, "Cập nhật vị trí thành công");
      } else {
        SnackBarHelper.showError(context, response['message'] ?? "Cập nhật thất bại");
      }
    } catch (e) {
      SnackBarHelper.showError(context, "Lỗi cập nhật vị trí: $e");
    }
  }

  Future<void> _showCompleteOrderConfirmation(String idOrder) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: 42,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Hoàn thành đơn việc?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Sau khi xác nhận, đơn hàng sẽ được chuyển sang trạng thái hoàn thành và không thể quay lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                if (_expectedIncome > 0) ...[
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.shade100,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'THU NHẬP DỰ KIẾN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          '+${FormatHelper.formatPrice(_expectedIncome)}đ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await completeOrder(idOrder);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          backgroundColor: ColorConfig.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkApprovalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('lastCheckApproval') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastCheck < 10 * 60 * 1000) {
      final remaining = 10 * 60 * 1000 - (now - lastCheck);
      setState(() => _remainingSeconds = (remaining / 1000).ceil());
      SnackBarHelper.showError(context, "Bạn cần chờ hết thời gian đếm ngược để kiểm tra lại.");
      return;
    }

    try {
      final response = await userService.getIsAcceptHaveApprovalRequestService();
      if (response['success'] == true) {
        final data = response['data'];
        final isAccept = data['isAcceptHaveApprovalRequest'] == true;

        if (isAccept) {
          SnackBarHelper.showSuccess(context, "Tài khoản đã được phê duyệt, vui lòng đăng nhập lại");
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/login');
          });
        } else {
          SnackBarHelper.showError(context, "Tài khoản chưa được phê duyệt, vui lòng liên hệ quản trị viên");
        }

        await prefs.setInt('lastCheckApproval', now);
        setState(() => _remainingSeconds = 10 * 60);
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
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _loadUserDetail() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString('role') ?? 'ktv';
    inforLogin = jsonDecode(prefs.getString('inforUserLogin') ?? '{}');
    isTechnicianActive = prefs.getBool('isTechnicianActive') == true;
    isProfileActive = prefs.getBool('isTechnicianActive') == true;
    statusAccount = prefs.getString('statusAccount') ?? 'inactive';

    idOrderWorking = await SharedPrefs.getValue(PrefType.string, "idOrderWorking") ?? "";
    isWorking = await SharedPrefs.getValue(PrefType.bool, "isWorking") ?? false;

    if (isWorking) {
      idOrderWorking = await SharedPrefs.getValue(PrefType.string, "idOrderWorking") ?? "";
      acceptedAt = await SharedPrefs.getValue(PrefType.string, "acceptedAt");

      // orderDetail được lưu dạng JSON string → decode thành Map
      final orderDetailRaw = await SharedPrefs.getValue(PrefType.string, "orderDetail");
      if (orderDetailRaw != null && orderDetailRaw.toString().isNotEmpty) {
        try {
          orderDetail = jsonDecode(orderDetailRaw.toString()) as Map<String, dynamic>;
          // appLog("Detail order: $orderDetailRaw");
        } catch (_) {
          orderDetail = null;
        }
      }
    }

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
      setState(() => isLoading = false);
      debugPrint("Lỗi load thông tin chi tiết người dùng: $e");
    }
  }

  Future<void> loadCheckWorkingOrder() async {
    final provider = Provider.of<OrderProvider>(
      context,
      listen: false,
    );

    try {
      setState(() {
        _errorMessage = '';
      });

      final success = await provider.checkWorkingOrder();

      if (success) {
        setState(() {
          orderDetail = provider.workingOrder["order"];
          isWorking = provider.workingOrder["isWorking"] ?? false;
          // appLog("orderDetail: $isWorking"); // true
          // appLog("orderDetail: ${provider.workingOrder}");

        });
      } else {
        setState(() {
          _errorMessage = provider.errorMessage ?? 'Không thể lấy thông tin đơn hàng';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      appLog('Error check working order: $e');
    }
  }

  Future<void> toggleUserStatus() async {
    if (technicianData == null || !isTechnicianActive) return;

    final newStatus = statusAccount == 'active' ? 'inactive' : 'active';
    setState(() => isUpdating = true);

    final response = await userService.changeStatusUserService({'status': newStatus});

    if (response['success'] == true) {
      setState(() {
        statusAccount = response['data']['status'];
        technicianData!['status'] = statusAccount;
        isUpdating = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('technician', jsonEncode(technicianData));
      await prefs.setString('statusAccount', response['data']['status']);

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Chuyển trạng thái: ${newStatus == 'inactive' ? 'Offline' : 'Online'}');
      }
    } else {
      setState(() => isUpdating = false);
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Lỗi đổi trạng thái: ${response['message'] ?? 'Lỗi không xác định'}');
      }
    }
  }

  Future<void> completeOrder(String idOrder) async {
    setState(() => isLoading = true);

    try {
      final data = {
        'orderId': idOrder,
        'result': 'done'
      };
      final response = await _orderService.updateStatus(data);
      // appLog("$response");

      if (response['success'] == true) {
        if (!mounted) return;

        await SharedPrefs.remove("orderDetail");
        await SharedPrefs.remove("idOrderWorking");
        await SharedPrefs.remove("acceptedAt");
        await SharedPrefs.saveValue(PrefType.bool, "isWorking", false);
        // await SharedPreferencesHelper.listAllKeyValue();

        setState(() {
          isWorking = false;
          isLoading = false;
          orderDetail = null;
          idOrderWorking = "";
          acceptedAt = null;
        });

        SnackBarHelper.showSuccess(context, "Bạn đã hoàn thành đơn thành công!");

        // Tự động reload lại trang sau 1 giây
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _loadUserDetail();
          }
        });
      } else {
        setState(() => isLoading = false);
        SnackBarHelper.showError(context, response['message'] ?? "Có lỗi xảy ra khi hoàn thành đơn");
      }
    } catch (e) {
      debugPrint('Error accepting order: $e');
      setState(() => isLoading = false);
      SnackBarHelper.showError(context, "Lỗi: $e");
    }
  }

  bool get _isOnline => isTechnicianActive && isProfileActive && statusAccount == 'active';

  // ─── Helpers lấy field từ orderDetail theo cấu trúc JSON thực tế ───

  /// Tên dịch vụ
  String get _orderServiceName => orderDetail?['nameService'] ?? 'Không xác định';

  /// Địa chỉ
  String get _orderAddress => orderDetail?['address'] ?? 'Không có địa chỉ';

  /// Giá tiền
  int get _expectedIncome => (orderDetail?['pricing']['technicianReceiveAmount'] ?? 0) as int;
  int get _totalBill => (orderDetail?['pricing']['finalAmount'] ?? 0) as int;

  // /// Tên khách hàng – field `customer` có thể null trong JSON
  // String get _orderCustomerName {
  //   final customer = orderDetail?['customer'];
  //   if (customer == null) return 'Không rõ';
  //   String fullNameCustomer = orderDetail?['customer']['fullname'] ?? "KHông có tên";
  //   return fullNameCustomer;
  // }
  //
  // String get _phoneCustomer {
  //   final customer = orderDetail?['customer'];
  //   if (customer == null) return 'Không rõ';
  //   String phoneCustomer = orderDetail?['customer']['phone'] ?? "Không có SĐT";
  //   return phoneCustomer;
  // }

  /// Thời gian thực hiện từ serviceTimePrice
  String get _orderDuration {
    final stp = orderDetail?['serviceTimePrice'];
    if (stp == null) return '';
    final duration = stp['duration'];
    return duration != null ? '$duration phút' : '';
  }

  /// Thời gian đặt hàng (submittedAt)
  String get _orderSubmittedAt {
    final raw = orderDetail?['submittedAt'];
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Loại đơn
  String get _orderType {
    final type = orderDetail?['typeOrder'] ?? '';
    return type == 'order-now' ? 'Đặt ngay' : type;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorConfig.primaryBackground,
      child: isLoading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
        color: ColorConfig.primary,
        onRefresh: _loadUserDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: avatar + info + notification ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
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
                        child: technicianData?['avatar']?['url'] != null
                            ? Image.network(
                          FormatHelper.formatNetworkImageUrl(
                              technicianData!['avatar']['url']),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                              'lib/assets/images/avatar_placeholder.png'),
                        )
                            : Image.asset(
                          'lib/assets/images/avatar_placeholder.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          Row(
                            children: [
                              Text(
                                'Trạng thái: ',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                              Text(
                                statusAccount == 'inactive' ? 'Offline' : 'Online',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: statusAccount == 'inactive'
                                      ? Colors.red.shade400
                                      : Colors.green.shade500,
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            context.push(TechnicianRouterConfig.notifications);
                          },
                          icon: const Icon(
                            Icons.notifications_outlined,
                            size: 28,
                          ),
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

                const SizedBox(height: 16),

                if (isTechnicianActive) ...[
                  // ── Status toggle + location update ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorConfig.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Trạng thái',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
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
                                activeTrackColor:
                                ColorConfig.secondary.withOpacity(0.3),
                                inactiveThumbColor: Colors.grey.shade400,
                                inactiveTrackColor: Colors.grey.shade300,
                                onChanged:
                                isProfileActive ? (_) => toggleUserStatus() : null,
                              ),
                            ),
                          ],
                        ),

                        Tooltip(
                          message: 'Cập nhật vị trí hiện tại',
                          child: Material(
                            color: ColorConfig.primary,
                            borderRadius: BorderRadius.circular(40),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(40),
                              onTap: isUpdatingLocation
                                  ? null
                                  : () async {
                                final shouldUpdate =
                                await _showLocationUpdateConfirmation();

                                if (shouldUpdate == true) {
                                  await _getCurrentLocation(context);
                                  await _updateLocation();
                                }
                              },

                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),

                                child: isUpdatingLocation
                                    ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(
                                  Icons.my_location,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildShortcutItem(
                          icon: Icons.history,
                          label: 'Lịch sử đơn',
                          onTap: () => context.push(TechnicianRouterConfig.historyOrder),
                        ),
                        _buildShortcutItem(
                          icon: Icons.attach_money,
                          label: 'Doanh thu',
                          onTap: () => context.push(TechnicianRouterConfig.statistical),
                        ),
                        _buildShortcutItem(
                          icon: Icons.account_tree,
                          label: 'Dịch vụ',
                          onTap: () => context.push(TechnicianRouterConfig.updateTechnicianService),
                        ),
                        _buildShortcutItem(
                          icon: Icons.person,
                          label: 'Cập nhật',
                          onTap: () => context.push(TechnicianRouterConfig.updateProfileTechnician),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildOrderCard(),
                  // _buildListNextBookOrder(),

                ] else ...[
                  // ── Inactive profile warning ──
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
                        "Kiểm tra lại sau: "
                            "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:"
                            "${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 26, color: ColorConfig.secondary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Dialog xác nhận cập nhật vị trí
  Future<bool?> _showLocationUpdateConfirmation() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.my_location,
                color: ColorConfig.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Cập nhật vị trí hiện tại',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Vị trí hiện tại sẽ được sử dụng để hiển thị và đề xuất các khách hàng ở gần khu vực của bạn, giúp tăng khả năng nhận việc phù hợp. Bạn có muốn cập nhật vị trí ngay bây giờ không?',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Để sau',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConfig.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cập nhật',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard() {
    final idOrderWorking = orderDetail?["_id"];
    final customerId = orderDetail?["customerId"];

    if (isWorking && orderDetail != null) {
      return GestureDetector(
        onTap: () {
          context.push(
            '${TechnicianRouterConfig.detailsOrder}/${idOrderWorking}',
          );
        },
        child: Container(
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
              // ── Header card ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: ColorConfig.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark_border_outlined,
                      size: 18,
                      color: ColorConfig.textWhite,
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'ĐƠN ĐANG THỰC HIỆN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: ColorConfig.textWhite,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Text(
                          'Chi tiết đơn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ColorConfig.textWhite.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: ColorConfig.textWhite.withOpacity(0.9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên dịch vụ
                    Row(
                      children: [
                        Icon(Icons.spa, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _orderServiceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Loại đơn
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _orderType,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Khách hàng
                    _buildInfoRow(
                      Icons.person_outline,
                      'Khách hàng: ${customerId["fullname"]}',
                    ),

                    const SizedBox(height: 8),

                    _buildInfoRow(
                      Icons.phone,
                      'SĐT: ${customerId["phone"]}',
                    ),

                    const SizedBox(height: 8),

                    // Địa chỉ
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      _orderAddress,
                      expandText: true,
                    ),

                    const SizedBox(height: 8),

                    // Thời gian đặt
                    if (_orderSubmittedAt.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        'Đặt lúc: $_orderSubmittedAt',
                      ),

                    // Thời lượng
                    if (_orderDuration.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.timer_outlined,
                        'Thời lượng: $_orderDuration',
                      ),
                    ],

                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Khách cần thanh toán',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${FormatHelper.formatPrice(_totalBill)} đ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorConfig.textError,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Thu nhập dự kiến',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '+${FormatHelper.formatPrice(_expectedIncome)} đ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorConfig.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Nút xác nhận hoàn thành
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCompleteOrderConfirmation(idOrderWorking),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: const Text('Xác nhận hoàn thành'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConfig.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty state ──
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
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Widget helper để render 1 dòng thông tin với icon
  Widget _buildInfoRow(IconData icon, String text, {bool expandText = false}) {
    return Row(
      crossAxisAlignment:
      expandText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        expandText
            ? Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)))
            : Text(text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ],
    );
  }
}