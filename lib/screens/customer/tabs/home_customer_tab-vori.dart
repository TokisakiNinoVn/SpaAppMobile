import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../helper/check_login_helper.dart';
import '../../../helper/snackbar_helper.dart';
import '../../../services/banner_service.dart';
import 'package:spa_app/helper/location_helper.dart';

import '../../../utils/address_util.dart';

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
  bool checkPermissionLocation = false;

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      _loadBanners();
      _startCouponTimer();
      _checkLogin();
      await _checkPermissionLocation();
      if(checkPermissionLocation) {
        await _loadAddressCustomer();
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
      SnackBarHelper.showError(context, 'Lỗi khi tải banner');
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
  Future<void> _checkPermissionLocation() async {
    try {
      checkPermissionLocation = await LocationHelper.isLocationReady();
      print("✅ checkPermissionLocation sau check: $checkPermissionLocation");

    } catch (e) {
      print('Error loading services: $e');
    }
  }

  Future<void> _loadAddressCustomer() async {
    try {
      _locationText = await AddressUtil.getFormatAddressProvince();
    } catch (e) {
      print('Error loading services: $e');
    }
  }

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

      final address = await AddressUtil.getAddressFromLatLng(
        pos.latitude,
        pos.longitude,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', pos.latitude);
      await prefs.setDouble('lng', pos.longitude);
      await prefs.setString('address', address ?? '');

      if (!mounted) return;
      setState(() {
        _locationText = address ??
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _locationLoading = false;
      });

      _currentAddress = address;
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
                _buildLocationBar(isDark),
              ],
            ),
          ),
        ],
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
                  checkPermissionLocation == true
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
                  checkPermissionLocation == true
                      ? 'Vị trí bạn: $_locationText'
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
                  checkPermissionLocation == true ? 'Cập nhật' : 'Cho phép',
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
}