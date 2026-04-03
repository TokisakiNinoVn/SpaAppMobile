import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/technician_service.dart';

import '../../routes/customer_config.dart';

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

  final Color _primaryColor = const Color(0xFF8B7355);
  final Color _secondaryColor = const Color(0xFFD4B996);
  final Color _accentColor = const Color(0xFFC19A6B);
  final Color _backgroundColor = const Color(0xFFF8F5F0);
  final Color _textColor = const Color(0xFF5D4037);

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
          backgroundColor: liked ? _primaryColor : Colors.grey,
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


      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chọn dịch vụ ${_selectedService!["name"]}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Điều hướng đến màn hình đặt lịch với thông tin dịch vụ
      Future.delayed(const Duration(milliseconds: 1500), () {
        context.go(
          CustomerRouterConfig.createOrder,
          extra: {
            'technician': _technicianDetails?["_id"],
            // 'service': _selectedService,
            // 'selectedDuration': selectedDuration,
            // 'selectedPrice': selectedPrice,
            'serviceTimePrice': serviceTimePrice,
          },
        );
      });
    }
  }

  // Hàm format tiền tệ
  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} triệu';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return price.toString();
    }
  }

  // Lấy avatar hoặc ảnh đầu tiên
  String _getAvatarUrl() {
    if (_technicianDetails == null) return "https://via.placeholder.com/400x400?text=No+Image";

    if (_technicianDetails!["avatar"] != null &&
        _technicianDetails!["avatar"]["url"] != null) {
      return _technicianDetails!["avatar"]["url"];
    }
    if (_technicianDetails!["images"] != null &&
        _technicianDetails!["images"].isNotEmpty) {
      return _technicianDetails!["images"][0]["url"];
    }
    return "https://via.placeholder.com/400x400?text=No+Image";
  }

  // Lấy danh sách ảnh
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
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: _textColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Chi tiết Kỹ thuật viên",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
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
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: _textColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Chi tiết Kỹ thuật viên",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
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
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadTechnicianDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: _textColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Chi tiết Kỹ thuật viên",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textColor,
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
            _buildTechnicianInfo(),
            _buildDescription(),
            _buildServicesSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider(List<String> imageUrls) {
    return SizedBox(
      height: 400,
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
                    image: NetworkImage(imageUrls[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),

          // Indicators
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

          // Nút yêu thích
          Positioned(
            top: 16,
            right: 16,
            child: InkWell(
              onTap: _toggleFavorite,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : _primaryColor,
                  size: 28,
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
                      _technicianDetails!["fullName"] ?? "Không có tên",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Kinh nghiệm: ${_technicianDetails!["experience"] ?? "Không có"}",
                      style: TextStyle(
                        fontSize: 14,
                        color: _textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.star,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _technicianDetails!["rate"]?.toString() ?? "0.0",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Thông tin chi tiết
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_technicianDetails!["yearOfBirth"] != null)
                _buildInfoChip(
                  icon: Icons.cake,
                  text: "${_technicianDetails!["yearOfBirth"]}",
                ),

              _buildInfoChip(
                icon: Icons.person,
                text: _getGenderText(),
              ),

              if (_technicianDetails!["province"] != null)
                _buildInfoChip(
                  icon: Icons.location_city,
                  text: _technicianDetails!["province"],
                ),

              // if (_technicianDetails!["districts"] != null &&
              //     _technicianDetails!["districts"].isNotEmpty)
              //   _buildInfoChip(
              //     icon: Icons.location_on,
              //     text: "${_technicianDetails!["districts"].length} quận",
              //   ),
            ],
          ),

          // const SizedBox(height: 16),

          // Địa chỉ
          // if (_technicianDetails!["address"] != null)
          //   Row(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Icon(
          //         Icons.location_pin,
          //         color: _primaryColor,
          //         size: 20,
          //       ),
          //       const SizedBox(width: 8),
          //       Expanded(
          //         child: Text(
          //           _technicianDetails!["address"],
          //           style: TextStyle(
          //             fontSize: 14,
          //             color: _textColor.withOpacity(0.7),
          //           ),
          //           maxLines: 2,
          //           overflow: TextOverflow.ellipsis,
          //         ),
          //       ),
          //     ],
          //   ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _secondaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: _textColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final bio = _technicianDetails!["bio"] ?? "Không có thông tin giới thiệu";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon(
              //   Icons.description,
              //   color: _primaryColor,
              //   size: 20,
              // ),
              // const SizedBox(width: 8),
              Text(
                "Giới thiệu",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: TextStyle(
              fontSize: 14,
              color: _textColor.withOpacity(0.8),
              height: 1.6,
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
              color: _textColor.withOpacity(0.5),
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
              //   color: _primaryColor,
              //   size: 24,
              // ),
              // const SizedBox(width: 8),
              Text(
                "Dịch vụ",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...services.map<Widget>((service) {
            return _buildServiceItem(service);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final timePrices = service["timePrices"] as List<dynamic>? ?? [];
    final name = service["name"] as String? ?? "Không có tên";
    final description = service["description"] as String? ?? "";

    // Tìm giá thấp nhất và cao nhất
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
        color: Colors.white,
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
        padding: const EdgeInsets.all(16.0),
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
                          color: _textColor,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: _textColor.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Hiển thị khoảng giá
                      if (minPrice > 0 && maxPrice > 0)
                        Text(
                          minPrice == maxPrice
                              ? "${_formatPrice(minPrice)} VNĐ"
                              : "${_formatPrice(minPrice)} - ${_formatPrice(maxPrice)} VNĐ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showBookingBottomSheetFunction(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text("Đặt đơn"),
                ),
              ],
            ),

            if (timePrices.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _secondaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _secondaryColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "$duration phút",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${_formatPrice(price)} VNĐ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                            fontSize: 12,
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
                  color: _primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Đặt dịch vụ",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
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
                color: _textColor,
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
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            Text(
              "Chọn thời gian:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),

            const SizedBox(height: 12),

            // Lựa chọn thời gian
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
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? _primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? _primaryColor : _secondaryColor,
                            width: 2,
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
                                color: isSelected ? Colors.white : _textColor,
                              ),
                            ),
                            Text(
                              "${_formatPrice(price)} VNĐ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : _primaryColor,
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
                      color: _textColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Hiển thị tổng tiền
            if (_selectedTimeIndex != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _secondaryColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tổng tiền:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    Text(
                      "${_formatPrice(timePrices[_selectedTimeIndex!]["price"])} VNĐ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Nút xác nhận
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTimeIndex != null ? _confirmBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}