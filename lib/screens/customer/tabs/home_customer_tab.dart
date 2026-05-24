import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/screens/customer/tabs/components/feature_item.dart';
import 'package:spa_app/screens/customer/tabs/components/feature_section.dart';
import 'package:spa_app/screens/customer/tabs/components/promo_section.dart';
import 'package:spa_app/services/customer_service.dart';
import 'package:spa_app/services/discount_service.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import '../../../helper/check_login_helper.dart';
import '../../../helper/snackbar_helper.dart';
import '../../../services/banner_service.dart';
import '../../../services/information_service.dart';
import 'package:spa_app/helper/location_helper.dart';
import 'package:spa_app/utils/address_util.dart';

import 'widgets/featured_services_widgetv2.dart';
import 'widgets/home_header_widget.dart';
import 'widgets/home_shortcut_item.dart';
import 'widgets/location_bar_widget.dart';
import 'widgets/banner_section_widget.dart';
import 'widgets/featured_services_widget.dart';
import 'widgets/promo_card.dart';

class HomeCustomerTab extends StatefulWidget {
  const HomeCustomerTab({super.key});

  @override
  State<HomeCustomerTab> createState() => _HomeCustomerTabState();
}

class _HomeCustomerTabState extends State<HomeCustomerTab>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  final BannerService _bannerService = BannerService();
  final CustomerService _customerService = CustomerService();
  final InformationService _informationService = InformationService();
  final DiscountService _discountService = DiscountService();
  final UserService _userService = UserService();

  @override
  bool get wantKeepAlive => true;

  // ─── Banner Data from API ─────────────────────────────────
  List<Map<String, dynamic>> bannerData = [];
  List<dynamic> listHomeDiscount = [];
  List<Map<String, dynamic>> featuredServices = [];
  List<dynamic> _displayDiscounts = [];

  bool isLoading = true;
  bool _isHomeDiscountLoading = true;
  bool _isBannerLoading = true;
  bool _isBalanceLoading = true;
  bool _isFeaturedServiceLoading = true;

  String? _bannerError;
  String? _currentAddress;
  int balance = 0;

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
  final int _notificationCount = 1;

  // ─── Support Button State ─────────────────────────────────
  bool _showSupportButton = true;

  @override
  void initState() {
    super.initState();

    _bannerController = PageController();
    _couponController = PageController(viewportFraction: 0.85);
    _loadData();
  }

  Future<void> _loadData() async {
    // Nếu đã có banner data rồi thì không loading lại
    if (bannerData.isNotEmpty) {
      setState(() {
        isLoading = false;
        _showSupportButton = true;
      });
      return;
    }

    setState(() {
      isLoading = true;
      _showSupportButton = true;
    });

    try {
      await Future.wait([
        _loadBanners(),
        _checkLogin(),
        _initLocationState(),
        _loadFeatureService(),
        _loadHomeDiscount()
      ]);

      if (_isLogin) {
        await _loadBalance();
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    _bannerTimer?.cancel();

    await Future.wait([
      _loadBanners(forceRefresh: true),
      _checkLogin(),
      _loadHomeDiscount(),
      if(_isLogin)
        _loadBalance(),

    ]);
  }

  Future<void> _loadBanners({bool forceRefresh = false}) async {
    // Nếu đã có data và không force refresh thì bỏ qua
    if (!forceRefresh && bannerData.isNotEmpty) {
      return;
    }

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

  Future<void> _loadBalance() async {
    setState(() {
      _isBalanceLoading = true;
    });
    try {
      final response = await _userService.getBalanceUserService();
      balance = response["data"]["balance"] ?? 0;
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Lỗi khi tải số dư');
      }
      balance = 0;
      appLog("Lỗi khi tải số dư: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isBalanceLoading = false;
        });
      }
    }
  }

  Future<void> _loadHomeDiscount() async {
    setState(() {
      _isHomeDiscountLoading = true;
    });
    try {
      final response = await _discountService.listHome();
      listHomeDiscount = response["data"] ?? [];
      // appLog("${listHomeDiscount}");

      final random = Random();
      final randomDiscounts = List<dynamic>.from(listHomeDiscount)..shuffle(random);
      _displayDiscounts = randomDiscounts.take(2).toList();
      // appLog("${_displayDiscounts}");
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Lỗi khi tải mã giảm giá');
      }
      balance = 0;
      appLog("Lỗi khi tải mã giảm giá: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isHomeDiscountLoading = false;
        });
      }
    }
  }

  Future<void> _loadFeatureService({bool forceRefresh = false}) async {
    // Nếu đã có data và không force refresh thì bỏ qua
    if (!forceRefresh && featuredServices.isNotEmpty) {
      return;
    }

    setState(() {
      _isFeaturedServiceLoading = true;
      // _bannerError = null;
    });

    try {
      final response = await _informationService.listFeatureServicePublic();
      // appLog("response: ${response['data']}");
      if (response['data'] != null) {
        final List<dynamic> data = response['data'];

        setState(() {
          featuredServices = data.map((item) {
            return {
              'image': item['fileId']?['url'] ?? '',
              'title': item['title'] ?? 'Banner',
              'description': item['description'] ?? '',
              'id': item['_id'],
              'tag': item['tag'],
              'startPrice': item['startPrice']
            };
          }).toList();

          _isFeaturedServiceLoading = false;
        });
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bannerError = 'Không thể tải danh sách dịch vụ: $e';
          _isFeaturedServiceLoading = false;
        });
        SnackBarHelper.showError(context, 'Lỗi khi tải banner');
      }
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (bannerData.length > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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

  // ─── Hiển thị BottomSheet với danh sách kênh hỗ trợ ───────
  void _showSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4845A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: Color(0xFFD4845A),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kênh hỗ trợ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Chọn kênh liên lạc phù hợp với bạn',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Danh sách kênh hỗ trợ
              ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: AppConfig.supportChannels.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[300],
                  indent: 70,
                ),
                itemBuilder: (context, index) {
                  final channel = AppConfig.supportChannels[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: channel.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        channel.iconAsset,
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon nếu không tìm thấy ảnh
                          return Icon(
                            _getFallbackIcon(channel.type),
                            color: channel.color,
                            size: 24,
                          );
                        },
                      ),
                    ),
                    title: Text(
                      channel.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      channel.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorConfig.primary.withOpacity(.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: ColorConfig.primary,
                      ),
                    ),
                    onTap: () => _openSupportChannel(channel),
                  );
                },
              ),
              const SizedBox(height: 20),
              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Phản hồi trong vòng 24h',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fallback icon khi không load được ảnh
  IconData _getFallbackIcon(SupportType type) {
    switch (type) {
      case SupportType.zalo:
        return Icons.chat;
      case SupportType.messenger:
        return Icons.message;
      case SupportType.phone:
        return Icons.phone;
      case SupportType.email:
        return Icons.email;
      case SupportType.telegram:
        return Icons.telegram;
    }
  }

  // ─── Mở ứng dụng tương ứng ───────────────────────────────
  Future<void> _openSupportChannel(SupportChannel channel) async {
    // Đóng bottom sheet trước khi mở app
    Navigator.pop(context);

    try {
      bool launched = false;

      switch (channel.type) {
        case SupportType.zalo:
        case SupportType.messenger:
        case SupportType.telegram:
        // Thử mở app nếu có
          if (channel.packageName != null) {
            if (Platform.isAndroid) {
              launched = await launchUrl(
                Uri.parse('${channel.packageName}://'),
                mode: LaunchMode.externalApplication,
              );
            } else if (Platform.isIOS) {
              // iOS scheme cho các app
              String iosUrl = '';
              switch (channel.type) {
                case SupportType.zalo:
                  iosUrl = 'zalo://';
                  break;
                case SupportType.messenger:
                  iosUrl = 'fb-messenger://';
                  break;
                case SupportType.telegram:
                  iosUrl = 'tg://';
                  break;
                default:
                  break;
              }
              if (iosUrl.isNotEmpty) {
                launched = await launchUrl(
                  Uri.parse(iosUrl),
                  mode: LaunchMode.externalApplication,
                );
              }
            }
          }

          // Nếu không mở được app thì mở web
          if (!launched) {
            launched = await launchUrl(
              Uri.parse(channel.url),
              mode: LaunchMode.platformDefault,
            );
          }
          break;

        case SupportType.phone:
          launched = await launchUrl(
            Uri.parse(channel.url),
            mode: LaunchMode.externalApplication,
          );
          break;

        case SupportType.email:
          launched = await launchUrl(
            Uri.parse(channel.url),
            mode: LaunchMode.platformDefault,
          );
          break;
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở ${channel.name}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening support channel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi mở ${channel.name}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _couponController.dispose();
    // _couponTimer.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String _mapRouter(int index) {
      switch (index) {
        case 0:
          return CustomerRouterConfig.orderNow;
        case 1:
          return CustomerRouterConfig.listBookTechnician;
        case 2:
          return CustomerRouterConfig.automaticMatching;
        default:
          return "";
      }
    }

    // final random = Random();
    //
    // final randomDiscounts = List<dynamic>.from(listHomeDiscount)
    //   ..shuffle(random);
    //
    // final displayDiscounts = randomDiscounts.take(2).toList();

    super.build(context);
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: ColorConfig.primary,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      HomeHeaderWidget(
                        isLogin: _isLogin,
                        inforUser: inforUser,
                        notificationCount: _notificationCount,
                      ),
                      LocationBarWidget(
                        checkPermissionLocation: checkPermissionLocation,
                        locationText: _locationText,
                        locationLoading: _locationLoading,
                        locationCooldownSeconds: _locationCooldownSeconds,
                        onLocationTap: _onLocationButtonTap,
                        formatCooldown: _formatCooldown,
                      ),
                      if (_isLogin) ...[
                        SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // LEFT (gộp 1 dòng)
                                Row(
                                  children: [
                                    Text('Ví Zen: ', style: TextStyle(fontSize: 14, color: Colors.black54)),
                                    _isBalanceLoading
                                        ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: ColorConfig.primary,),
                                    )
                                        : Text(
                                      '${FormatHelper.formatPrice(balance)} đ',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),

                                // RIGHT BUTTON
                                GestureDetector(
                                  onTap: () {
                                    context.push(CustomerRouterConfig.choosePackage);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F1E8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Nạp tiền',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 18),
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: _isDisplayBanner
                              ? BannerSectionWidget(
                                  isBannerLoading: _isBannerLoading,
                                  bannerError: _bannerError,
                                  bannerData: bannerData,
                                  currentBannerIndex: _currentBannerIndex,
                                  bannerController: _bannerController,
                                  onBannerPageChanged: (index) {
                                    setState(() => _currentBannerIndex = index);
                                  },
                                )
                              : SizedBox.shrink(),
                        ),
                      ),

                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                        child: Column(
                          children: [
                            HomeShortcutRow(
                              items: [
                                HomeShortcutItem(
                                  icon: Icons.calendar_today,
                                  label: "Đặt lịch ngay",
                                  onTap: () {},
                                ),
                                HomeShortcutItem(
                                  icon: Icons.spa,
                                  label: "Dịch vụ",
                                ),
                                HomeShortcutItem(
                                  icon: Icons.card_giftcard,
                                  label: "Ưu đãi",
                                  isHot: true,
                                ),
                                // HomeShortcutItem(
                                //   icon: Icons.article,
                                //   label: "Tin tức",
                                // ),
                                HomeShortcutItem(
                                  icon: Icons.headset_mic,
                                  label: "Hỗ trợ 24/7",
                                ),
                              ],
                            ),

                            if (featuredServices.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text("Dịch vụ nổi bật", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),

                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                child: Row(
                                  children: List.generate(featuredServices.length, (index) {
                                    final item = featuredServices[index];

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 7),
                                      child: SizedBox(
                                        width: 140,
                                        child: FeaturedServicesWidgetV2(
                                          title: item['title'],
                                          description: item['description'],
                                          tag: item['tag'],
                                          imageUrl: item['image'],
                                          router: _mapRouter(index),
                                          startPrice: item['startPrice'] ?? 0,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ] else
                              const SizedBox(),

                            const SizedBox(height: 10,),

                            PromoSection(
                              onViewAll: () {},
                              children: _displayDiscounts.isEmpty
                                  ? []
                                  : _displayDiscounts.asMap().entries.map((entry) {
                                final index = entry.key;
                                final discount = entry.value;
                                final urlImage = discount['image']?['url'] ?? "";
                                final fullUrlImage = FormatHelper.formatNetworkImageUrl(urlImage);
                                // appLog("${fullUrlImage}");

                                final isPercent = discount['type'] == 'percentage';
                                final value = discount['value'] ?? 0;

                                // Ảnh xen kẽ:
                                // index chẵn -> ảnh 1
                                // index lẻ -> ảnh 2
                                final image = index % 2 == 0
                                    ? ThemeConfig.urlImage1DiscountHome
                                    : ThemeConfig.urlImage2DiscountHome;

                                final code =
                                (discount['code'] ?? '').toString().trim();

                                final description =
                                (discount['description'] ?? '')
                                    .toString()
                                    .trim();

                                return PromoCard(
                                  // image: urlImage.isNotEmpty ? fullUrlImage : image,
                                  image: (urlImage.trim().isNotEmpty)
                                      ? fullUrlImage
                                      : image,

                                  title: code.isNotEmpty
                                      ? "Mã: $code"
                                      : "Ưu đãi đặc biệt",

                                  subtitle: description.isNotEmpty
                                      ? description
                                      : "Nhanh tay sử dụng ưu đãi trước khi kết thúc",

                                  newPrice: isPercent
                                      ? "Giảm $value%"
                                      : "${FormatHelper.formatPrice(value)} đ",

                                  discount: isPercent
                                      ? "Giảm $value%"
                                      : "Giảm ${FormatHelper.formatPrice(value)}",

                                  showCountdown: true,
                                  expiresAt: discount['expiresAt'],

                                  onTap: () {
                                    context.push(
                                      CustomerRouterConfig
                                          .listOrderNowTechnician,
                                    );
                                  },
                                );
                              }).toList(),
                            )

                          ],
                        ),
                      ),

                      FeatureSection(),
                      const SizedBox(height: 70),
                    ],
                  ),
                ),
              ],
            ),
            // Nút hỗ trợ floating
            if (_showSupportButton)
              Positioned(
                bottom: 20,
                right: 20,
                child: GestureDetector(
                  onTap: _showSupportBottomSheet,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColorConfig.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.headset_mic,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Hỗ trợ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSupportButton = false;
                            });
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Support Channel Model ─────────────────────────────────
enum SupportType {
  zalo,
  messenger,
  phone,
  email,
  telegram,
}

class SupportChannel {
  final String iconAsset;
  final String name;
  final String description;
  final Color color;
  final SupportType type;
  final String url;
  final String? packageName;

  SupportChannel({
    required this.iconAsset,
    required this.name,
    required this.description,
    required this.color,
    required this.type,
    required this.url,
    this.packageName,
  });
}