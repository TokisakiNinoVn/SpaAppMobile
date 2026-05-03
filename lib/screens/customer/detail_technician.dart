import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:spa_app/helper/check_login_helper.dart';
import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/technician_service.dart';
import '../../helper/format_helper.dart';
import '../../routes/config/customer_router_config.dart';

class DetailsTechnicianScreen extends StatefulWidget {
  final String id;
  final String type;
  const DetailsTechnicianScreen({
    super.key,
    required this.id,
    required this.type
  });

  @override
  State<DetailsTechnicianScreen> createState() => _DetailsTechnicianScreenState();
}

class _DetailsTechnicianScreenState extends State<DetailsTechnicianScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final LikeService _likeService = LikeService();

  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  bool _showAppBar = false;

  int _currentPage = 0;
  bool _isFavorite = false;
  Map<String, dynamic>? _selectedService;
  bool _showBottomBar = false;

  String? _selectedServiceId;
  int _selectedTimeIndex = 0;

  Map<String, dynamic>? _technicianDetails;
  bool _isLoading = true;
  bool isLogin = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.offset > 250 && !_showAppBar) {
        setState(() => _showAppBar = true);
      } else if (_scrollController.offset <= 250 && _showAppBar) {
        setState(() => _showAppBar = false);
      }
    });
    checkLogin();
  }

  Future<void> checkLogin() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();
    if (loggedIn) {
      isLogin = true;
      _loadTechnicianDetails();
    } else
      context.go(GlobalRouterConfig.loginOTP);
  }

  Future<void> _loadTechnicianDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _technicianService.getDetailsTechnicianForCustomerService(widget.id);
      if (response['success'] == true) {
        setState(() {
          _technicianDetails = response['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải thông tin kỹ thuật viên');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading technician details: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_technicianDetails == null) return;

    try {
      final payload = {"technicianId": _technicianDetails!["_id"]};
      final response = await _likeService.createLikeService(payload);

      final bool liked = response['liked'] == true;
      final String message = response['message'] ?? '';

      setState(() {
        _isFavorite = liked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: liked ? ColorConfig.primary : Colors.grey,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra, vui lòng thử lại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Hiển thị bottom bar khi nhấn vào chip thời gian
  void _showBottomBarForService(Map<String, dynamic> service, int timeIndex) {
    setState(() {
      _selectedService = service;
      _selectedServiceId = service["_id"];
      _selectedTimeIndex = timeIndex;
      _showBottomBar = true;
    });
  }

  void _hideBottomBar() {
    setState(() {
      _showBottomBar = false;
      _selectedService = null;
      _selectedServiceId = null;
      _selectedTimeIndex = 0;
    });
  }

  void _confirmBooking() {
    if (_selectedService != null && _selectedTimeIndex != null && _technicianDetails != null) {
      // Lấy thông tin dịch vụ đã chọn
      final serviceTimePrice = _selectedService!["timePrices"][_selectedTimeIndex!];
      final nameServiceSelect = _selectedService!['name'];

      // Ẩn bottom bar trước khi điều hướng
      _hideBottomBar();

      // Điều hướng đến màn hình đặt lịch
      if(widget.type == 'now') {
        context.go(
          CustomerRouterConfig.createOrderNow,
          extra: {
            'technician': {
              "id": _technicianDetails!["_id"],
              "fullName": _technicianDetails!["fullName"],
              "avatar": _technicianDetails!["avatar"],
              "rate": _technicianDetails!["rate"],
            },
            'nameService': nameServiceSelect,
            'serviceTimePrice': serviceTimePrice,
          },
        );
      } else {
        context.go(
          CustomerRouterConfig.createBookOrder,
          extra: {
            'technician': {
              "id": _technicianDetails!["_id"],
              "fullName": _technicianDetails!["fullName"],
              "avatar": _technicianDetails!["avatar"],
              "rate": _technicianDetails!["rate"],
            },
            'nameService': nameServiceSelect,
            'serviceTimePrice': serviceTimePrice,
          },
        );
      }
    }
  }

  List<String> _getImageUrls() {
    final List<String> urls = [];

    if (_technicianDetails == null) {
      urls.add("https://via.placeholder.com/400x400?text=No+Image");
      return urls;
    }

    if (_technicianDetails!["avatar"] != null &&
        _technicianDetails!["avatar"]["url"] != null) {
      urls.add(_technicianDetails!["avatar"]["url"]);
    }

    if (_technicianDetails!["images"] != null) {
      for (var image in _technicianDetails!["images"]) {
        if (image["url"] != null) {
          urls.add(image["url"]);
        }
      }
    }

    if (urls.isEmpty) {
      urls.add("https://via.placeholder.com/400x400?text=No+Image");
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ColorConfig.primaryBackground,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: ColorConfig.primaryBackground,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Đã xảy ra lỗi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorConfig.textBlack),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ColorConfig.textBlack.withOpacity(0.7)),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadTechnicianDetails,
                style: ElevatedButton.styleFrom(backgroundColor: ColorConfig.primary),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_technicianDetails == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy thông tin kỹ thuật viên')));
    }

    final imageUrls = _getImageUrls();

    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      body: Stack(
        children: [
          /// SCROLL VIEW
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 370,
                pinned: true,
                backgroundColor: ColorConfig.primaryBackground,
                elevation: 0,
                automaticallyImplyLeading: false,

                /// 👇 AppBar khi scroll xuống
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showAppBar ? 1 : 0,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Chi tiết Kỹ thuật viên",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ColorConfig.black,
                        ),
                      ),
                    ],
                  ),
                ),

                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageSlider(_getImageUrls()),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildTechnicianInfo(),
                      _buildDescription(),
                      _buildServicesSection(),

                      _buildRatingBreakdown(),
                      const SizedBox(height: 20),
                      const SizedBox(height: 100),
                      if (_showBottomBar) const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ],
          ),

          /// 🔥 BACK BUTTON FIXED (QUAN TRỌNG)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showAppBar ? 0 : 1,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          /// 🔻 BOTTOM BAR
          if (_showBottomBar && _selectedService != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
        ],
      ),


    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ColorConfig.primaryBackground,
      elevation: 0,
      title: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(40)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1A1A)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Chi tiết Kỹ thuật viên",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConfig.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlider(List<String> imageUrls) {
    return SizedBox(
      height: 370,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(FormatHelper.formatNetworkImageUrl(imageUrls[index])),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                    (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FormatHelper.formatNameTechnician(_technicianDetails!["fullName"] ?? "Không có tên"),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ColorConfig.black),
                ),
              ],
            ),
          ),
          // GestureDetector(
          //   onTap: _toggleFavorite,
          //   child: AnimatedContainer(
          //     duration: const Duration(milliseconds: 200),
          //     width: 40,
          //     height: 40,
          //     decoration: BoxDecoration(color: ColorConfig.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(40)),
          //     child: Icon(Icons.favorite, color: ColorConfig.primary, size: 20),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    Widget _buildCheckItem(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.check, color: Colors.green, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: ColorConfig.black.withOpacity(0.85)))),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ColorConfig.primary, width: .5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              "https://i.pinimg.com/1200x/23/10/6c/23106cb9b6f1888a3b5ffe604ec81359.jpg",
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCheckItem("Không mất tiền tip, không phí di chuyển"),
                _buildCheckItem("Bồi thường nếu không đúng người"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = _technicianDetails?["serviceIds"] ?? [];
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text("Không có dịch vụ nào", style: TextStyle(fontSize: 16, color: ColorConfig.black.withOpacity(0.5)))),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dịch vụ của tôi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ColorConfig.black)),
          const SizedBox(height: 16),
          ...services.map<Widget>((service) => _buildServiceItem(service)).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final timePrices = service["timePrices"] as List<dynamic>? ?? [];
    final name = service["name"] as String? ?? "Không có tên";
    final serviceId = service["_id"] as String?;
    final isSelected = (_selectedServiceId == serviceId);
    final currentTimePrice = timePrices.isNotEmpty && _selectedTimeIndex < timePrices.length
        ? timePrices[_selectedTimeIndex]
        : null;

    // Giá hiển thị mặc định (lấy từ time đầu tiên)
    final defaultPrice = timePrices.isNotEmpty ? timePrices[0]["price"] : 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? ColorConfig.primary : Colors.transparent, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ColorConfig.black)),
                      const SizedBox(height: 4),
                      Text(
                        FormatHelper.formatPrice(currentTimePrice["price"]),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ColorConfig.black),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if(isSelected) {
                      _hideBottomBar();
                    } else {
                      _showBottomBarForService(service, 0);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: ColorConfig.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSelected ? "Đã đặt" : "Đặt",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isSelected ? Icons.check : Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(height: 1, width: double.infinity, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            if (timePrices.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: timePrices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final duration = item["duration"] as int? ?? 0;
                    final isTimeSelected = isSelected && _selectedTimeIndex == index;

                    return GestureDetector(
                      onTap: () {
                        // Khi nhấn vào chip thời gian: chọn service và time index, hiển thị bottom bar
                        _showBottomBarForService(service, index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          color: isTimeSelected ? ColorConfig.primary : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.black26, width: .4),
                        ),
                        child: Text(
                          "$duration phút",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isTimeSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Phần hiển thị đánh giá chi tiết (1-5 sao)
  Widget _buildRatingBreakdown() {
    final Map<int, int> ratingCounts = {
      5: 120,
      4: 45,
      3: 12,
      2: 5,
      1: 3,
    };

    final totalReviews = ratingCounts.values.reduce((a, b) => a + b);
    final averageRating = _technicianDetails!["rate"]?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Đánh giá",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConfig.black,
            ),
          ),
          /// ===== HÀNG 1 =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// CỘT 1: SỐ RATE
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: ColorConfig.black,
                ),
              ),

              const SizedBox(width: 16),

              /// CỘT 2: STAR + TEXT
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HÀNG 1: ICON STAR
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.floor()
                            ? Icons.star
                            : (index < averageRating.ceil()
                            ? Icons.star_half
                            : Icons.star_border),
                        size: 18,
                        color: ColorConfig.yellow,
                      );
                    }),
                  ),

                  const SizedBox(height: 4),

                  /// HÀNG 2: TEXT REVIEW
                  Text(
                    "$totalReviews đánh giá",
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorConfig.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// ===== HÀNG 2: BREAKDOWN =====
          Column(
            children: List.generate(5, (star) {
              final starLevel = 5 - star;
              final count = ratingCounts[starLevel] ?? 0;
              final percent =
              totalReviews > 0 ? (count / totalReviews) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Row(
                        children: [
                          Text(
                            "$starLevel",
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              ColorConfig.black.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.star,
                            size: 14,
                            color: ColorConfig.yellow,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey.shade200,
                          color: ColorConfig.primary,
                          minHeight: 6,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    SizedBox(
                      width: 35,
                      child: Text(
                        "$count",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                          ColorConfig.black.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }


  /// Bottom bar hiển thị gói dịch vụ đã chọn
  Widget _buildBottomBar() {
    if (_selectedService == null) return Container();
    final timePrices = _selectedService!["timePrices"] as List<dynamic>? ?? [];
    final currentTimePrice = timePrices.isNotEmpty && _selectedTimeIndex < timePrices.length
        ? timePrices[_selectedTimeIndex]
        : null;
    final price = currentTimePrice != null ? currentTimePrice["price"] as int? ?? 0 : 0;
    final duration = currentTimePrice != null ? currentTimePrice["duration"] as int? ?? 0 : 0;
    final serviceName = _selectedService!["name"] as String? ?? "Dịch vụ";

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _hideBottomBar,
            child: Container(width: 50, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serviceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ColorConfig.textBlack)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('$duration phút', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        const SizedBox(width: 12),
                        Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('1 dịch vụ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(FormatHelper.formatPrice(price), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ColorConfig.textBlack, letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text('VNĐ', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _hideBottomBar,
                  child: const Text("Hủy", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConfig.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _confirmBooking,
                  child: const Text("Đặt ngay", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}