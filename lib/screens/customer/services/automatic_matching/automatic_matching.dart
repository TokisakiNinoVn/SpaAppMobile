import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/service_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/notification_service.dart';
import '../../../../helper/format_helper.dart';
import '../../../../routes/config/customer_router_config.dart';

class AutomaticMatchingScreen extends StatefulWidget {
  @override
  State<AutomaticMatchingScreen> createState() =>
      _AutomaticMatchingScreenState();
}

class _AutomaticMatchingScreenState extends State<AutomaticMatchingScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final NotificationService _notificationService = NotificationService();
  final ServiceService _serviceService = ServiceService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> allServices = [];
  List<dynamic> filteredServices = [];

  int? _selectedServiceIndex;
  int? _selectedTimeIndex;

  Map<String, dynamic>? _selectedService;
  Map<String, dynamic>? _selectedTimePrice;

  @override
  void initState() {
    super.initState();
    _loadAllServices();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllServices() async {
    try {
      final response = await _serviceService.listBaseService();
      // appLog('List service: $response');
      setState(() {
        allServices = response['data'] ?? [];
        filteredServices = allServices;
      });
    } catch (e) {
      print("Error loading services: $e");
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredServices = allServices
          .where((s) => (s['name'] as String).toLowerCase().contains(query))
          .toList();
      // Reset selection if selected item is filtered out
      if (_selectedService != null &&
          !filteredServices.contains(_selectedService)) {
        _selectedServiceIndex = null;
        _selectedTimeIndex = null;
        _selectedService = null;
        _selectedTimePrice = null;
      }
    });
  }

  String formatPrice(int price) {
    return price
        .toString()
        .replaceAllMapped(
        RegExp(r'(\d{3})(?=\d)'), (m) => '${m[1]}.') +
        ' đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      body: Column(
        children: [
          /// ─── HEADER ───────────────────────────────────────────
          _buildHeader(context),

          /// ─── SEARCH BAR ───────────────────────────────────────
          _buildSearchBar(),

          /// ─── SERVICE LIST ─────────────────────────────────────
          Expanded(
            child: allServices.isEmpty
                ? Center(
              child: CircularProgressIndicator(color: ColorConfig.primary),
            )
                : filteredServices.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) =>
                  _buildServiceTile(context, index),
            ),
          ),
        ],
      ),

      /// ─── BOTTOM BAR ───────────────────────────────────────────
      bottomNavigationBar:
      _selectedService != null ? _buildBottomBar() : null,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // HEADER
  // ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black26.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: ColorConfig.textBlack,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    "Chọn dịch vụ phù hợp với bạn",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: ColorConfig.textBlack,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          // color: Colors.grey.withOpacity(.2),
          border: Border.all(
            color: Colors.black26,
            width: .4,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: ColorConfig.primary.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(fontSize: 14, color: ColorConfig.textBlack),
          decoration: InputDecoration(
            hintText: "Tìm kiếm dịch vụ...",
            hintStyle: TextStyle(
              fontSize: 14,
              color: ColorConfig.textBlack.withOpacity(.7),
            ),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: ColorConfig.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: Icon(Icons.close_rounded,
                  size: 18, color: Colors.grey.shade400),
            )
                : null,
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTile(BuildContext context, int index) {
    final service = filteredServices[index];
    final timePrices = service['timePrices'] as List;

    final globalIndex = allServices.indexOf(service);
    final isSelected = _selectedServiceIndex == globalIndex;

    final currentTimePrice = (isSelected && _selectedTimeIndex != null)
        ? timePrices[_selectedTimeIndex!]
        : timePrices.first;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? ColorConfig.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== HÀNG 1 =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Tên + Giá
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorConfig.textBlack
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatPrice(currentTimePrice['price']),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ColorConfig.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Nút Đặt / Đã đặt
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedServiceIndex = globalIndex;
                      _selectedTimeIndex = 0;
                      _selectedService = service;
                      _selectedTimePrice = timePrices[0];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      // color: isSelected
                      //     ? Colors.green
                      //     : ColorConfig.primary,
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

            const SizedBox(height: 12),

            /// ===== DIVIDER =====
            Container(
              height: 1,
              width: double.infinity,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 12),

            /// ===== HÀNG 2: DURATION =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(timePrices.length, (i) {
                  final item = timePrices[i];
                  final isTimeSelected =
                      isSelected && _selectedTimeIndex == i;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedServiceIndex = globalIndex;
                        _selectedTimeIndex = i;
                        _selectedService = service;
                        _selectedTimePrice = item;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: isTimeSelected
                            ? ColorConfig.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.black26,
                          width: .4,
                        ),
                      ),
                      child: Text(
                        '${item['duration']} phút',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isTimeSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ──────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ──────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            "Không tìm thấy dịch vụ",
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Thử từ khoá khác nhé",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // BOTTOM BAR
  // ──────────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          /// Info row
          Row(
            children: [
              /// Service name pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedService?['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ColorConfig.textBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedTimePrice?['duration']} phút · 1 dịch vụ',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                formatPrice(_selectedTimePrice?['price'] ?? 0),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ColorConfig.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// CTA Button
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConfig.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {

                context.push(
                 CustomerRouterConfig.createAutomaticMatchingOrder,
                    extra: {
                      "service": _selectedService,
                      "timePrice": _selectedTimePrice,
                    },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Đặt ngay",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}