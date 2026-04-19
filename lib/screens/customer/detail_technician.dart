import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/technician_service.dart';

import '../../helper/format_helper.dart';
import '../../routes/config/customer_router_config.dart';

class DetailsTechnicianScreen extends StatefulWidget {
  final String id;
  const DetailsTechnicianScreen({super.key, required this.id});

  @override
  State<DetailsTechnicianScreen> createState() => _DetailsTechnicianScreenState();
}

class _DetailsTechnicianScreenState extends State<DetailsTechnicianScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final LikeService _likeService = LikeService();

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFavorite = false;
  Map<String, dynamic>? _selectedService;
  int? _selectedTimeIndex;
  bool _showBookingBottomSheet = false;

  // State management
  Map<String, dynamic>? _technicianDetails;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTechnicianDetails();
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

  void _showBookingBottomSheetFunction(Map<String, dynamic> service) {
    setState(() {
      _selectedService = service;
      _selectedTimeIndex = null;
      _showBookingBottomSheet = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildBookingBottomSheet(setModalState);
          },
        );
      },
    ).then((_) {
      setState(() {
        _showBookingBottomSheet = false;
      });
    });
  }

  void _confirmBooking() {
    if (_selectedService != null && _selectedTimeIndex != null && _technicianDetails != null) {
      Navigator.pop(context);

      // Lấy thông tin dịch vụ đã chọn
      final selectedDuration = _selectedService!["timePrices"][_selectedTimeIndex!]["duration"];
      final selectedPrice = _selectedService!["timePrices"][_selectedTimeIndex!]["price"];
      final serviceTimePrice = _selectedService!["timePrices"][_selectedTimeIndex!];

      // Điều hướng đến màn hình đặt lịch với thông tin dịch vụ
      // Future.delayed(const Duration(milliseconds: 1500), () {
        context.go(
          CustomerRouterConfig.createOrder,
          extra: {
            // 'technician': _technicianDetails?["_id"],
            'technician': {
              "id": _technicianDetails!["_id"],
              "fullName": _technicianDetails!["fullName"],
              "avatar": _technicianDetails!["avatar"],
              "rate": _technicianDetails!["rate"],
            },
            // 'service': _selectedService,
            // 'selectedDuration': selectedDuration,
            'nameService': _selectedService!["name"],
            'serviceTimePrice': serviceTimePrice,
          },
        );
      // });
    }
  }

  List<String> _getImageUrls() {
    final List<String> urls = [];

    if (_technicianDetails == null) {
      urls.add("https://via.placeholder.com/400x400?text=No+Image");
      return urls;
    }

    // Thêm avatar nếu có
    if (_technicianDetails!["avatar"] != null &&
        _technicianDetails!["avatar"]["url"] != null) {
      urls.add(_technicianDetails!["avatar"]["url"]);
    }

    // Thêm các ảnh khác
    if (_technicianDetails!["images"] != null) {
      for (var image in _technicianDetails!["images"]) {
        if (image["url"] != null) {
          urls.add(image["url"]);
        }
      }
    }

    // Nếu không có ảnh nào, thêm ảnh placeholder
    if (urls.isEmpty) {
      urls.add("https://via.placeholder.com/400x400?text=No+Image");
    }

    return urls;
  }

  // Lấy thông tin giới tính
  String _getGenderText() {
    if (_technicianDetails == null) return "Không xác định";

    final gender = _technicianDetails!["gender"] ?? "";
    if (gender == "female") return "Nữ";
    if (gender == "male") return "Nam";
    return "Không xác định";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ColorConfig.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF1A1A1A),
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
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: ColorConfig.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF1A1A1A),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Đã xảy ra lỗi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConfig.textBlack,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorConfig.textBlack.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadTechnicianDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_technicianDetails == null) {
      return const Scaffold(
        body: Center(
          child: Text('Không tìm thấy thông tin kỹ thuật viên'),
        ),
      );
    }

    final imageUrls = _getImageUrls();

    return Scaffold(
      backgroundColor: ColorConfig.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1A1A1A),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSlider(imageUrls),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              child: Column(
                children: [
                  _buildTechnicianInfo(),
                  _buildDescription(),
                  _buildServicesSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
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
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(FormatHelper.formatNetworkImageUrl(imageUrls[index])),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
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
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
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
                  FormatHelper.formatNameTechnician(
                      _technicianDetails!["fullName"] ?? "Không có tên"),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorConfig.black,
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.solidStar,
                      size: 14,
                      color: ColorConfig.yellow.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _technicianDetails!["rate"]?.toString() ?? "0.0",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConfig.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: _toggleFavorite,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorConfig.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.favorite,
                color: ColorConfig.primary,
                size: 20,
              ),
            ),
          ),
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
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(
                Icons.check,
                color: Colors.green,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: ColorConfig.black.withOpacity(0.85),
                ),
              ),
            ),
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
          border: Border.all(
            color: ColorConfig.primary,
            width: 1,
          )
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
              mainAxisAlignment: MainAxisAlignment.center,
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
        child: Center(
          child: Text(
            "Không có dịch vụ nào",
            style: TextStyle(
              fontSize: 16,
              color: ColorConfig.black.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon(
              //   Icons.spa,
              //   color: ColorConfig.primary,
              //   size: 24,
              // ),
              // const SizedBox(width: 8),
              Text(
                "Dịch vụ của tôi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConfig.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...services.map<Widget>((service) {
            return _buildServiceItem(service);
          }).toList(),

          const SizedBox(height: 12),

          Text(
            "Đánh giá",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: ColorConfig.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final timePrices = service["timePrices"] as List<dynamic>? ?? [];
    final name = service["name"] as String? ?? "Không có tên";
    final description = service["description"] as String? ?? "";

    int minPrice = 0;
    int maxPrice = 0;
    if (timePrices.isNotEmpty) {
      final prices = timePrices.map<int>((tp) => tp["price"] as int? ?? 0).toList();
      minPrice = prices.reduce((a, b) => a < b ? a : b);
      maxPrice = prices.reduce((a, b) => a > b ? a : b);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xE0F1F1F1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ColorConfig.black,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showBookingBottomSheetFunction(service),
                  style: TextButton.styleFrom(
                    backgroundColor: ColorConfig.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Đặt"),
                ),

              ],
            ),

            if (timePrices.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: timePrices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final timePrice = entry.value;
                  final duration = timePrice["duration"] as int? ?? 0;
                  final price = timePrice["price"] as int? ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: ColorConfig.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ColorConfig.primary,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "$duration phút",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: ColorConfig.black,
                            fontSize: 12
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingBottomSheet(void Function(void Function()) setModalState) {
    if (_selectedService == null) return Container();
    final timePrices = _selectedService!["timePrices"] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: ColorConfig.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Đặt dịch vụ",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ColorConfig.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              _selectedService!["name"] ?? "Không có tên",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorConfig.black,
              ),
            ),

            if (_selectedService!["description"] != null &&
                (_selectedService!["description"] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _selectedService!["description"],
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorConfig.black.withOpacity(0.7),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            Text(
              "Chọn thời gian:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ColorConfig.black,
              ),
            ),

            const SizedBox(height: 10),

            if (timePrices.isNotEmpty)
              Column(
                children: List.generate(
                  timePrices.length,
                      (index) {
                    final timePrice = timePrices[index];
                    final duration = timePrice["duration"] as int? ?? 0;
                    final price = timePrice["price"] as int? ?? 0;
                    final isSelected = _selectedTimeIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          _selectedTimeIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? ColorConfig.primary : Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: isSelected ? ColorConfig.primary : ColorConfig.primary.withOpacity(.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$duration phút",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : ColorConfig.black,
                              ),
                            ),
                            Text(
                              "${FormatHelper.formatPrice(price)} VNĐ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : ColorConfig.textBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "Không có thông tin giá dịch vụ",
                    style: TextStyle(
                      color: ColorConfig.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            const Divider(height: 18),
            const SizedBox(height: 8),

            // Hiển thị tổng tiền
            if (_selectedTimeIndex != null)
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tổng dịch vụ:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorConfig.black,
                      ),
                    ),
                    Text(
                      "${FormatHelper.formatPrice(timePrices[_selectedTimeIndex!]["price"])} VNĐ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorConfig.textBlack,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Nút xác nhận
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTimeIndex != null ? _confirmBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                ),
                child: const Text(
                  "Xác nhận đặt đơn",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}