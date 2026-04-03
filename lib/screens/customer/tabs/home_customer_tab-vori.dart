import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../helper/check_login_helper.dart';
import '../../../helper/snackbar_helper.dart';
import '../../../services/banner_service.dart';

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
  String? _bannerError;

  int _currentBannerIndex = 0;
  late PageController _bannerController;
  Timer? _bannerTimer;

  // ─── Coupon ───────────────────────────────────────────────
  final List<Map<String, dynamic>> coupons = [
    {
      'code': 'RELAX30',
      'discount': '30%',
      'description': 'Massage toàn thân',
      'expiry': '31/12/2025',
      'color': const Color(0xFFE91E8C),
      'icon': Icons.spa,
    },
    {
      'code': 'SKIN20',
      'discount': '20%',
      'description': 'Chăm sóc da mặt',
      'expiry': '30/11/2025',
      'color': const Color(0xFF7C4DFF),
      'icon': Icons.face_retouching_natural,
    },
    {
      'code': 'NEWUSER',
      'discount': '50K',
      'description': 'Khách hàng mới',
      'expiry': '01/01/2026',
      'color': const Color(0xFFFF6D00),
      'icon': Icons.card_giftcard,
    },
    {
      'code': 'WEEKEND15',
      'discount': '15%',
      'description': 'Cuối tuần vàng',
      'expiry': '31/12/2025',
      'color': const Color(0xFF00897B),
      'icon': Icons.weekend,
    },
  ];

  int _currentCouponIndex = 0;
  late PageController _couponController;
  late Timer _couponTimer;

  // ─── Location ─────────────────────────────────────────────
  String? _locationText;
  bool _locationLoading = false;

  // ─── User Info ────────────────────────────────────────────
  Map<String, dynamic>? inforUser;
  bool _isLogin = false;
  bool _isDisplayBanner = false;

  // ─── Notification badge ───────────────────────────────────
  final int _notificationCount = 3;

  // ─── Services ─────────────────────────────────────────────
  final String massageImage =
      'https://i.pinimg.com/736x/b5/0f/b8/b50fb8f8e4ea9423c61b36f6dc3edbcd.jpg';
  final String skincareImage =
      'https://i.pinimg.com/736x/fd/c4/05/fdc4051627ff930ccd716a523706449c.jpg';

  final List<Map<String, dynamic>> quickServices = [
    {'icon': Icons.spa, 'label': 'Massage', 'color': const Color(0xFFE91E8C)},
    {
      'icon': Icons.face_retouching_natural,
      'label': 'Skincare',
      'color': const Color(0xFF7C4DFF)
    },
    {
      'icon': Icons.self_improvement,
      'label': 'Yoga',
      'color': const Color(0xFF00897B)
    },
    {
      'icon': Icons.local_florist,
      'label': 'Aromatherapy',
      'color': const Color(0xFFFF6D00)
    },
    {
      'icon': Icons.water_drop,
      'label': 'Body Wrap',
      'color': const Color(0xFF1E88E5)
    },
  ];

  @override
  void initState() {
    super.initState();

    _bannerController = PageController();
    _couponController = PageController(viewportFraction: 0.85);
    _loadBanners();
    _startCouponTimer();
    _checkLogin();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isBannerLoading = true;
      _bannerError = null;
    });

    try {
      final response = await _bannerService.listPublicBanner();
      print("response banner: $response");
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

        // Start banner timer only if there are banners
        if (bannerData.isNotEmpty) {
          _startBannerTimer();
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      setState(() {
        _bannerError = 'Không thể tải banner: $e';
        _isBannerLoading = false;
      });
      SnackbarHelper.showError(context, 'Lỗi khi tải banner');
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

  void _startCouponTimer() {
    _couponTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentCouponIndex + 1) % coupons.length;
      setState(() => _currentCouponIndex = next);
      if (_couponController.hasClients) {
        _couponController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
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

  // ─── Location ─────────────────────────────────────────────
  Future<void> _requestLocation() async {
    setState(() => _locationLoading = true);
    HapticFeedback.lightImpact();

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationText = null;
            _locationLoading = false;
          });
          _showLocationDeniedSnackBar();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationText = null;
          _locationLoading = false;
        });
        _showOpenSettingsDialog();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      if (!mounted) return;
      setState(() {
        _locationText =
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _locationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationLoading = false);
      debugPrint('Location error: $e');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF8F4F0),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                _buildHeader(isDark),
                _buildLocationBar(isDark),
                // if (!_isLogin) _buildLoginPrompt(isDark),
                if(_isDisplayBanner)...[
                  _buildBannerSection(),
                ],
                const SizedBox(height: 5),
                _buildFeaturedServices(isDark),
                const SizedBox(height: 24),
                _buildCouponSection(isDark),
                const SizedBox(height: 20),
                _buildQuickServices(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
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

  Widget _buildLoginPrompt(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFD4845A).withOpacity(0.1),
              const Color(0xFFE91E8C).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4845A).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Color(0xFFE91E8C), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đăng ký để nhận ưu đãi đặc biệt và trải nghiệm dịch vụ tốt nhất',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : const Color(0xFF5D4037),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD4845A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Đăng ký',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: _locationLoading ? null : _requestLocation,
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
                  _locationText != null
                      ? Icons.location_on
                      : Icons.location_off_outlined,
                  key: ValueKey(_locationText),
                  size: 20,
                  color: _locationText != null
                      ? const Color(0xFF4CAF50)
                      : (isDark ? Colors.grey[400] : Colors.grey[500]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _locationText != null
                      ? 'Vị trí của bạn: $_locationText'
                      : 'Nhấn để cấp quyền vị trí',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _locationText != null
                        ? FontWeight.w600
                        : FontWeight.bold,
                    color: _locationText != null
                        ? (isDark ? Colors.green[300] : const Color(0xFF2E7D32))
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43A047), Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _locationText != null ? 'Cập nhật' : 'Cho phép',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                            borderRadius: BorderRadius.circular(0),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.75),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
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
                                style: TextStyle(
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
                                    colors: [Color(0xFFD4845A), Color(0xFFE91E8C)],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Handle banner click
                                  },
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
                          margin: const EdgeInsets.symmetric(horizontal: 4),
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
          // _buildSectionHeader('Dịch vụ nổi bật', isDark),
          const SizedBox(height: 16),
          _buildImageServiceCard(
            title: 'Massage tại nhà',
            description: 'Toàn thân · 60 / 90 / 120 phút',
            router: '/home-customer/list-technician',
            imageUrl: massageImage,
            tag: 'Phổ biến',
            tagColor: const Color(0xFFE91E8C),
          ),
          const SizedBox(height: 16),
          _buildImageServiceCard(
            title: 'Chăm sóc da mặt',
            description: 'Sạch sâu · Dưỡng ẩm · Trẻ hoá',
            router: '',
            imageUrl: skincareImage,
            tag: 'Mới',
            tagColor: const Color(0xFF7C4DFF),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSectionHeader('Mã giảm giá', isDark,
              trailing: TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: Color(0xFFD4845A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              )),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _couponController,
            onPageChanged: (i) => setState(() => _currentCouponIndex = i),
            itemCount: coupons.length,
            itemBuilder: (_, i) {
              final c = coupons[i];
              final isActive = i == _currentCouponIndex;
              return AnimatedScale(
                scale: isActive ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 300),
                child: _buildCouponCard(c, isDark),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            coupons.length,
                (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentCouponIndex == i ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentCouponIndex == i
                    ? (coupons[_currentCouponIndex]['color'] as Color)
                    : Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> c, bool isDark) {
    final color = c['color'] as Color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(c['icon'] as IconData,
                            color: Colors.white.withOpacity(0.95), size: 28),
                        const SizedBox(height: 6),
                        Text(
                          c['discount'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'GIẢM',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          c['description'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'HSD: ${c['expiry']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _copyCouponCode(c['code'] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  c['code'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy,
                                    color: Colors.white, size: 14),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildQuickServices(bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: quickServices.length,
        itemBuilder: (_, i) {
          final s = quickServices[i];
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (s['color'] as Color).withOpacity(0.15),
                        (s['color'] as Color).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (s['color'] as Color).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    s['icon'] as IconData,
                    color: s['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4845A), Color(0xFFE91E8C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF2D1B0E),
              ),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

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
                    border:
                    Border.all(color: Colors.white.withOpacity(0.4), width: 1),
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