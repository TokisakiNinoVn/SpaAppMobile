import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:geolocator/geolocator.dart';


import '../../../helper/check_login_helper.dart';
import '../../../helper/snackbar_helper.dart';
import '../../../services/banner_service.dart';
import 'package:spa_app/helper/location_helper.dart';
import 'package:spa_app/utils/address_util.dart';
class HomeCustomerTab extends StatefulWidget {
  const HomeCustomerTab({super.key});

  @override
  State<HomeCustomerTab> createState() => _HomeCustomerTabState();
}

class _HomeCustomerTabState extends State<HomeCustomerTab>
    with TickerProviderStateMixin {
  final BannerService _bannerService = BannerService();

  // ─── Banner Data from API ─────────────────────────────────
  List<Map<String, dynamic>> bannerData = [];
  bool _isBannerLoading = true;
  bool isLoading = true;
  String? _bannerError;
  String? _currentAddress;

  int _currentBannerIndex = 0;
  late PageController _bannerController;
  Timer? _bannerTimer;

  int _currentCouponIndex = 0;
  late PageController _couponController;
  late Timer _couponTimer;

  // ─── Location ─────────────────────────────────────────────
  String? _locationText;
  String provinceText = '';
  bool _locationLoading = false;

  /// Thời gian còn lại (giây) trước khi được phép cập nhật vị trí lại.
  /// = 0 nghĩa là đã hết cooldown.
  int _locationCooldownSeconds = 0;
  Timer? _cooldownTimer;

  static const int _locationCooldownDuration = 300; // 5 phút = 300 giây
  static const String _prefLastLocationUpdate = 'last_location_update';

  // ─── User Info ────────────────────────────────────────────
  Map<String, dynamic>? inforUser;
  bool _isLogin = false;
  bool _isDisplayBanner = false;
  bool checkPermissionLocation = false;

  // ─── Notification badge ───────────────────────────────────
  final int _notificationCount = 3;

  // ─── Services ─────────────────────────────────────────────
  final String massageImage =
      'https://i.pinimg.com/736x/b5/0f/b8/b50fb8f8e4ea9423c61b36f6dc3edbcd.jpg';
  final String skincareImage =
      'https://i.pinimg.com/736x/fd/c4/05/fdc4051627ff930ccd716a523706449c.jpg';

  final String skincareImage2 =
      'https://i.pinimg.com/736x/3e/0d/c2/3e0dc2ff82049cc97aac309f676ad115.jpg';

  @override
  void initState() {
    super.initState();

    _bannerController = PageController();
    _couponController = PageController(viewportFraction: 0.85);
    _loadData();
  }

  // ─── Load toàn bộ dữ liệu (trừ vị trí) ──────────────────
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _loadBanners(),
        _checkLogin(),
        _initLocationState(), // chỉ đọc trạng thái, KHÔNG xin quyền
      ]);
      // _startCouponTimer();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ─── Pull-to-refresh: load lại mọi thứ TRỪ vị trí ───────
  Future<void> _onRefresh() async {
    // Huỷ timer cũ để tránh trùng
    _bannerTimer?.cancel();

    await Future.wait([
      _loadBanners(),
      _checkLogin(),
    ]);
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isBannerLoading = true;
      _bannerError = null;
    });

    try {
      final response = await _bannerService.listPublicBanner();
      _isDisplayBanner = response["display"];

      if (response != null && response['data'] != null) {
        final List<dynamic> data = response['data'];
        setState(() {
          bannerData = data.map((item) {
            return {
              'image': FormatHelper.formatNetworkImageUrl(item['urlImage'] ?? ''),
              'title': item['title'] ?? 'Banner',
              'description': item['content'] ?? '',
              'id': item['_id'],
            };
          }).toList();
          _isBannerLoading = false;
        });

        if (bannerData.isNotEmpty) {
          _startBannerTimer();
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bannerError = 'Không thể tải banner: $e';
          _isBannerLoading = false;
        });
        SnackBarHelper.showError(context, 'Lỗi khi tải banner');
      }
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (bannerData.length > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentBannerIndex + 1) % bannerData.length;
        setState(() => _currentBannerIndex = next);
        if (_bannerController.hasClients) {
          _bannerController.animateToPage(
            next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  Future<void> _checkLogin() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();
    if (loggedIn) await _loadInforUser();
    if (!mounted) return;
    setState(() => _isLogin = loggedIn);
  }

  Future<void> _loadInforUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('inforUserLogin');
      final data = jsonString != null
          ? jsonDecode(jsonString) as Map<String, dynamic>
          : null;
      if (!mounted) return;
      setState(() => inforUser = data);
    } catch (e) {
      debugPrint('❌ Lỗi parse: $e');
      if (!mounted) return;
      setState(() => inforUser = null);
    }
  }

  // ─── Khởi tạo trạng thái vị trí (không xin quyền) ───────
  /// Đọc quyền hiện tại + địa chỉ đã lưu + cooldown từ SharedPreferences.
  /// KHÔNG tự động xin quyền – chỉ xin khi người dùng nhấn nút.
  Future<void> _initLocationState() async {
    try {
      // Kiểm tra quyền hiện tại mà KHÔNG hỏi thêm
      final permission = await Geolocator.checkPermission();
      final hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      // Đọc địa chỉ + cooldown đã lưu
      final prefs = await SharedPreferences.getInstance();
      final savedAddress = prefs.getString('address');
      final lastUpdateMs = prefs.getInt(_prefLastLocationUpdate) ?? 0;

      // Tính cooldown còn lại
      final elapsed =
          (DateTime.now().millisecondsSinceEpoch - lastUpdateMs) ~/ 1000;
      final remaining = _locationCooldownDuration - elapsed;

      if (!mounted) return;
      setState(() {
        checkPermissionLocation = hasPermission;
        _locationText = (hasPermission && (savedAddress?.isNotEmpty ?? false))
            ? savedAddress
            : null;
        _locationCooldownSeconds = (remaining > 0) ? remaining : 0;
      });

      // Nếu đang trong cooldown thì tiếp tục đếm ngược
      if (_locationCooldownSeconds > 0) {
        _startCooldownTimer();
      }
    } catch (e) {
      debugPrint('Error init location state: $e');
    }
  }

  // ─── Cooldown timer ───────────────────────────────────────
  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_locationCooldownSeconds > 0) {
          _locationCooldownSeconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String _formatCooldown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Xử lý nhấn nút vị trí ───────────────────────────────
  /// Nút "Cho phép" → xin quyền (lần đầu / bị từ chối)
  /// Nút "Cập nhật" → lấy vị trí mới (nếu hết cooldown)
  Future<void> _onLocationButtonTap() async {
    if (_locationLoading) return;

    if (!checkPermissionLocation) {
      // Chưa có quyền → xin quyền
      await _requestLocationPermission();
    } else {
      // Đã có quyền → cập nhật vị trí (kiểm tra cooldown)
      if (_locationCooldownSeconds > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                    'Vui lòng chờ ${_formatCooldown(_locationCooldownSeconds)} để cập nhật lại'),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      await _updateCurrentLocation();
    }
  }

  // ─── Xin quyền vị trí (chỉ gọi khi người dùng chủ động nhấn) ──
  Future<void> _requestLocationPermission() async {
    setState(() => _locationLoading = true);
    HapticFeedback.lightImpact();

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locationLoading = false);
        _showOpenSettingsDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _locationText = null;
          _locationLoading = false;
          checkPermissionLocation = false;
        });
        _showLocationDeniedSnackBar();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationText = null;
          _locationLoading = false;
          checkPermissionLocation = false;
        });
        _showOpenSettingsDialog();
        return;
      }

      // Đã được cấp quyền → lấy vị trí luôn
      if (!mounted) return;
      setState(() {
        checkPermissionLocation = true;
        _locationLoading = false;
      });
      await _updateCurrentLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationLoading = false);
      debugPrint('Permission request error: $e');
    }
  }

  // ─── Lấy & lưu vị trí mới ────────────────────────────────
  Future<void> _updateCurrentLocation() async {
    setState(() => _locationLoading = true);
    HapticFeedback.lightImpact();

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final address = await AddressUtil.getAddressFromLatLng(
        pos.latitude,
        pos.longitude,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', pos.latitude);
      await prefs.setDouble('lng', pos.longitude);
      await prefs.setString('address', address ?? '');
      // Lưu thời điểm cập nhật để tính cooldown
      await prefs.setInt(_prefLastLocationUpdate, DateTime.now().millisecondsSinceEpoch);

      if (!mounted) return;
      setState(() async {
        _locationText = address ??
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _locationLoading = false;
        _locationCooldownSeconds = _locationCooldownDuration;
      });

      _currentAddress = address;
      _startCooldownTimer();

      // Thông báo cập nhật thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Đã cập nhật vị trí thành công'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationLoading = false);
      debugPrint('Location update error: $e');
    }
  }

  void _showLocationDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bạn đã từ chối quyền truy cập vị trí'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cần quyền vị trí'),
        content: const Text(
            'Vui lòng mở Cài đặt và cấp quyền vị trí để sử dụng tính năng này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4845A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child:
            const Text('Mở cài đặt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _copyCouponCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Đã sao chép mã: $code'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _couponController.dispose();
    _couponTimer.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF8F4F0),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFFD4845A),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  _buildHeader(isDark),
                  _buildLocationBar(isDark),
                  if (_isDisplayBanner) ...[
                    _buildBannerSection(),
                  ],
                  const SizedBox(height: 5),
                  _buildFeaturedServices(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4845A), Color(0xFFE91E8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4845A).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xin chào 👋',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _isLogin
                      ? (inforUser?['fullName'] ??
                      inforUser?['phone'] ??
                      'Quý khách')
                      : 'Serene Spa!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2D1B0E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go(CustomerRouterConfig.toNotificationScreen);
                  },
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : const Color(0xFF2D1B0E),
                    size: 22,
                  ),
                ),
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE91E8C),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _notificationCount > 9 ? '9+' : '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar(bool isDark) {
    // Label & màu nút phải theo trạng thái
    final bool inCooldown =
        checkPermissionLocation && _locationCooldownSeconds > 0;
    final bool canUpdate =
        checkPermissionLocation && _locationCooldownSeconds == 0;

    final String buttonLabel = !checkPermissionLocation
        ? 'Cho phép'
        : inCooldown
        ? _formatCooldown(_locationCooldownSeconds)
        : 'Cập nhật';

    final List<Color> buttonGradient = inCooldown
        ? [Colors.grey.shade500, Colors.grey.shade600]
        : [const Color(0xFF43A047), const Color(0xFF00897B)];
    String _province = "";

    void _updateProvince() async {
      final result = await AddressUtil.formatAddressProvince(_locationText!);
      setState(() {
        _province = result;
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: _locationLoading ? null : _onLocationButtonTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _locationText != null
                ? (isDark
                ? const Color(0xFF1B3A2E).withOpacity(0.3)
                : const Color(0xFFE8F5E9))
                : (isDark ? Colors.grey[850] : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _locationText != null
                  ? const Color(0xFF4CAF50).withOpacity(0.5)
                  : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
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
                child: _locationLoading
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
                  color: _locationText != null
                      ? const Color(0xFF4CAF50)
                      : (isDark ? Colors.grey[400] : Colors.grey[500]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  checkPermissionLocation
                      ? (_locationText != null
                      ? 'Vị trí bạn: ${AddressUtil.formatAddressProvince(_locationText!)}'
                      : 'Đang xác định vị trí...')
                      : 'Nhấn để cấp quyền vị trí',

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _locationText != null
                        ? FontWeight.w600
                        : FontWeight.bold,
                    color: _locationText != null
                        ? (isDark
                        ? Colors.green[300]
                        : const Color(0xFF2E7D32))
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Nút hành động
              GestureDetector(
                onTap: _locationLoading || inCooldown
                    ? null
                    : _onLocationButtonTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: buttonGradient),
                    borderRadius: BorderRadius.circular(10),
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

  // Widget _buildBannerSection() {
  //   if (_isBannerLoading) {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  //       child: Container(
  //         height: 200,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(0),
  //           color: Colors.grey[300],
  //         ),
  //         child: const Center(
  //           child: CircularProgressIndicator(
  //             color: Color(0xFFD4845A),
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //
  //   if (_bannerError != null || bannerData.isEmpty) {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  //       child: Container(
  //         height: 200,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(0),
  //           color: Colors.grey[200],
  //         ),
  //         child: Center(
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Icon(
  //                 Icons.error_outline,
  //                 size: 48,
  //                 color: Colors.grey[400],
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 _bannerError ?? 'Không có banner',
  //                 style: TextStyle(
  //                   color: Colors.grey[600],
  //                   fontSize: 14,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 16),
  //     child: Column(
  //       children: [
  //         SizedBox(
  //           height: 200,
  //           child: Stack(
  //             children: [
  //               PageView.builder(
  //                 controller: _bannerController,
  //                 onPageChanged: (i) =>
  //                     setState(() => _currentBannerIndex = i),
  //                 itemCount: bannerData.length,
  //                 itemBuilder: (_, i) {
  //                   final item = bannerData[i];
  //                   return Stack(
  //                     children: [
  //                       ClipRRect(
  //                         borderRadius: BorderRadius.circular(0),
  //                         child: Image.network(
  //                           item['image'],
  //                           width: double.infinity,
  //                           height: 200,
  //                           fit: BoxFit.cover,
  //                           errorBuilder: (context, error, stackTrace) {
  //                             return Container(
  //                               color: Colors.grey[300],
  //                               child: const Icon(Icons.broken_image,
  //                                   size: 50, color: Colors.grey),
  //                             );
  //                           },
  //                         ),
  //                       ),
  //                       Container(
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(0),
  //                           gradient: LinearGradient(
  //                             begin: Alignment.centerLeft,
  //                             end: Alignment.centerRight,
  //                             colors: [
  //                               Colors.black.withOpacity(0.75),
  //                               Colors.transparent,
  //                               Colors.transparent,
  //                               Colors.black.withOpacity(0.2),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                       Positioned(
  //                         left: 20,
  //                         top: 28,
  //                         right: 20,
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               item['title'],
  //                               style: const TextStyle(
  //                                 color: Colors.white,
  //                                 fontSize: 22,
  //                                 fontWeight: FontWeight.w800,
  //                                 height: 1.2,
  //                               ),
  //                             ),
  //                             const SizedBox(height: 8),
  //                             Text(
  //                               item['description'],
  //                               style: TextStyle(
  //                                 color: Colors.white.withOpacity(0.95),
  //                                 fontSize: 13,
  //                               ),
  //                               maxLines: 2,
  //                               overflow: TextOverflow.ellipsis,
  //                             ),
  //                             const SizedBox(height: 16),
  //                             Container(
  //                               decoration: BoxDecoration(
  //                                 gradient: const LinearGradient(
  //                                   colors: [
  //                                     Color(0xFFD4845A),
  //                                     Color(0xFFE91E8C)
  //                                   ],
  //                                 ),
  //                                 borderRadius: BorderRadius.circular(30),
  //                               ),
  //                               child: ElevatedButton(
  //                                 onPressed: () {
  //                                   // Handle banner click
  //                                 },
  //                                 style: ElevatedButton.styleFrom(
  //                                   backgroundColor: Colors.transparent,
  //                                   foregroundColor: Colors.white,
  //                                   shadowColor: Colors.transparent,
  //                                   padding: const EdgeInsets.symmetric(
  //                                       horizontal: 20, vertical: 0),
  //                                   shape: RoundedRectangleBorder(
  //                                     borderRadius: BorderRadius.circular(30),
  //                                   ),
  //                                 ),
  //                                 child: const Text(
  //                                   'Đặt lịch ngay',
  //                                   style: TextStyle(
  //                                       fontSize: 13,
  //                                       fontWeight: FontWeight.bold),
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   );
  //                 },
  //               ),
  //               if (bannerData.length > 1)
  //                 Positioned(
  //                   bottom: 12,
  //                   left: 0,
  //                   right: 0,
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: List.generate(
  //                       bannerData.length,
  //                           (i) => AnimatedContainer(
  //                         duration: const Duration(milliseconds: 300),
  //                         width: _currentBannerIndex == i ? 24 : 8,
  //                         height: 8,
  //                         margin: const EdgeInsets.symmetric(horizontal: 4),
  //                         decoration: BoxDecoration(
  //                           color: _currentBannerIndex == i
  //                               ? Colors.white
  //                               : Colors.white.withOpacity(0.5),
  //                           borderRadius: BorderRadius.circular(4),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBannerSection() {
    if (_isBannerLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
            color: Colors.grey[300],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFD4845A),
            ),
          ),
        ),
      );
    }

    if (_bannerError != null || bannerData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
            color: Colors.grey[200],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  _bannerError ?? 'Không có banner',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _bannerController,
                  onPageChanged: (i) =>
                      setState(() => _currentBannerIndex = i),
                  itemCount: bannerData.length,
                  itemBuilder: (_, i) {
                    final item = bannerData[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: Image.network(
                            item['image'],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image,
                                    size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: const [0.0, 0.4, 0.7, 1.0],
                              colors: [
                                const Color(0xFF000000).withOpacity(1),
                                const Color(0xFF000000).withOpacity(0.8),
                                const Color(0xFF000000).withOpacity(0.4),
                                const Color(0xFF000000).withOpacity(0.15),
                              ],
                            ),
                          ),
                        ),

                        Positioned(
                          left: 20,
                          top: 28,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['description'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFD4845A),
                                      Color(0xFFE91E8C)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Đặt lịch ngay',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                if (bannerData.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        bannerData.length,
                            (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentBannerIndex == i ? 24 : 8,
                          height: 8,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _currentBannerIndex == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedServices(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildImageServiceCard(
            title: 'Đặt Kỹ thuật viên tại nhà',
            description: 'Dịch vụ massage & chăm sóc sức khỏe tại nhà theo yêu cầu',
            router: '/home-customer/list-technician',
            imageUrl: massageImage,
            tag: 'Phổ biến',
            tagColor: const Color(0xFFE91E8C),
          ),

          const SizedBox(height: 16),
          _buildImageServiceCard(
            title: 'Đặt lịch trước',
            description: 'Chọn kỹ thuật viên và thời gian phù hợp với bạn',
            router: CustomerRouterConfig.listBookTechnician,
            imageUrl: skincareImage,
            tag: 'Mới',
            tagColor: const Color(0xFF7C4DFF),
          ),

          const SizedBox(height: 16),
          _buildImageServiceCard(
            title: 'Ghép kỹ thuật viên tự động',
            description: 'Hệ thống sẽ chọn kỹ thuật viên phù hợp cho bạn',
            router: CustomerRouterConfig.automaticMatching,
            imageUrl: skincareImage2,
            tag: 'Mới',
            tagColor: const Color(0xFF7C4DFF),
          ),

        ],
      ),
    );
  }

  // Widget _buildSectionHeader(String title, bool isDark, {Widget? trailing}) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Row(
  //         children: [
  //           Container(
  //             width: 5,
  //             height: 24,
  //             decoration: BoxDecoration(
  //               gradient: const LinearGradient(
  //                 colors: [Color(0xFFD4845A), Color(0xFFE91E8C)],
  //                 begin: Alignment.topCenter,
  //                 end: Alignment.bottomCenter,
  //               ),
  //               borderRadius: BorderRadius.circular(3),
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Text(
  //             title,
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.w800,
  //               color: isDark ? Colors.white : const Color(0xFF2D1B0E),
  //             ),
  //           ),
  //         ],
  //       ),
  //       if (trailing != null) trailing,
  //     ],
  //   );
  // }

  Widget _buildImageServiceCard({
    required String title,
    required String description,
    required String imageUrl,
    required String router,
    required String tag,
    required Color tagColor,
  }) {
    return InkWell(
      onTap: () {
        if (router.isNotEmpty) context.go(router);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: tagColor.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}