import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/location_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/services/service_service.dart';
import 'package:spa_app/utils/address_util.dart';

class ListTechnicianOrderNow extends StatefulWidget {
  const ListTechnicianOrderNow({super.key});

  @override
  State<ListTechnicianOrderNow> createState() => _ListTechnicianOrderNowState();
}

class _ListTechnicianOrderNowState extends State<ListTechnicianOrderNow> {
  final TechnicianService _technicianService = TechnicianService();
  final ServiceService _serviceService = ServiceService();
  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> filteredTechnicians = [];
  List<Map<String, dynamic>> services = [];

  // Filter states
  String? selectedGender;
  String addressCustomer = "Chưa có vị trí";
  double? latValue;           // Sửa từ Double? thành double?
  double? longValue;          // Sửa từ Double? thành double?
  String? selectedServiceId;
  String searchQuery = '';

  // Loading & error states
  bool isLoading = true;
  bool checkPermissionLocation = true;
  double? currentLat;
  double? currentLng;
  String? errorMessage;       // Thêm biến lỗi

  // Check if any filter (gender only) is active for red dot
  bool get _hasActiveFilter => selectedGender != null;

  // Check if service filter is active (for styling)
  bool get _hasActiveServiceFilter => selectedServiceId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _loadListService();
      if (checkPermissionLocation) {
        await _loadPermissionLocation();
        await _getCurrentLocation();
        await _loadAddressCustomer();
      }
      await _loadListTechnician();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    final location = await LocationHelper.getSharedPreferencesLocation();
    if (location != null) {
      setState(() {
        currentLat = location.latitude;
        currentLng = location.longitude;
      });
    }
  }

  Future<void> _loadListService() async {
    try {
      final response = await _serviceService.listBaseService();
      if (response['success'] == true) {
        setState(() {
          services = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
      } else {
        print("============== Else ==================");
      }
    } catch (e) {
      print('Error loading services: $e');
    }
  }

  Future<void> _loadAddressCustomer() async {
    try {
      addressCustomer = await AddressUtil.getFormatAddressProvince();
    } catch (e) {
      print('Error loading services: $e');
    }
  }

  Future<void> _loadPermissionLocation() async {
    try {
      checkPermissionLocation = await LocationHelper.isLocationReady();
    } catch (e) {
      print('Error loading services: $e');
    }
  }

  Future<void> _loadListTechnician() async {
    try {
      var response;
      if (checkPermissionLocation) {
        response = await _technicianService.getListTechnicianForCustomer(
            currentLat, currentLng);
      } else {
        response = await _technicianService
            .getListTechnicianForCustomer(null, null);
      }
      if (response['success'] == true) {
        final data = List<Map<String, dynamic>>.from(response['data'] ?? []);
        setState(() {
          technicians = data;
          filteredTechnicians = List.from(data);
          errorMessage = null; // Xóa lỗi nếu thành công
        });
      } else {
        // Xử lý khi API trả về success=false
        setState(() {
          errorMessage = response['message'] ?? 'Không thể tải danh sách kỹ thuật viên';
          technicians = [];
          filteredTechnicians = [];
        });
        print("============== Else ==================");
      }
    } catch (e) {
      // Bắt lỗi ngoại lệ (mất mạng, timeout, ...)
      setState(() {
        errorMessage = 'Lỗi kết nối: ${e.toString()}';
        technicians = [];
        filteredTechnicians = [];
      });
      print('Error loading technicians: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      filteredTechnicians = technicians.where((tech) {
        // Filter by gender
        if (selectedGender != null && selectedGender!.isNotEmpty) {
          if (tech['gender'] != selectedGender) {
            return false;
          }
        }

        // Filter by service
        if (selectedServiceId != null && selectedServiceId!.isNotEmpty) {
          final techServices =
          List<Map<String, dynamic>>.from(tech['service'] ?? []);
          final hasService =
          techServices.any((service) => service['_id'] == selectedServiceId);
          if (!hasService) {
            return false;
          }
        }

        // Filter by search query
        if (searchQuery.isNotEmpty) {
          final fullName =
              tech['fullName']?.toString().toLowerCase() ?? '';
          final province =
              tech['province']?.toString().toLowerCase() ?? '';
          final districts = List<String>.from(tech['districts'] ?? [])
              .map((d) => d.toLowerCase())
              .join(' ');

          return fullName.contains(searchQuery.toLowerCase()) ||
              province.contains(searchQuery.toLowerCase()) ||
              districts.contains(searchQuery.toLowerCase());
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      selectedGender = null;
      selectedServiceId = null;
      searchQuery = '';
      filteredTechnicians = List.from(technicians);
    });
  }

  /// Lấy tên dịch vụ đã chọn để hiển thị trên chip
  String _getSelectedServiceLabel() {
    if (selectedServiceId == null) return "Loại dịch vụ";

    final service = services.cast<Map<String, dynamic>?>().firstWhere(
          (s) => s?['_id'] == selectedServiceId,
      orElse: () => null,
    );

    if (service == null) return "Loại dịch vụ";

    final name = service['name'] ?? "";
    if (name.length > 15) return "${name.substring(0, 15)}...";
    return name;
  }


  /// Bottom sheet lọc chung (chỉ còn giới tính)
  void _showFilterBottomSheet(BuildContext context) {
    String? tempSelectedGender = selectedGender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8D8C3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bộ lọc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ColorConfig.textBlack,
                        ),
                      ),
                      if (tempSelectedGender != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempSelectedGender = null;
                            });
                          },
                          child: Text(
                            'Xóa bộ lọc',
                            style: TextStyle(
                              color: ColorConfig.textBlack,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Gender filter
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giới tính',
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorConfig.textBlack,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Nam'),
                            selected: tempSelectedGender == 'male',
                            onSelected: (selected) {
                              setModalState(() {
                                tempSelectedGender = selected ? 'male' : null;
                              });
                            },
                            selectedColor: ColorConfig.primary.withOpacity(1),
                            backgroundColor: const Color(0xFFF9F5F0),
                            checkmarkColor: ColorConfig.white,
                            labelStyle: TextStyle(
                              color: tempSelectedGender == 'male'
                                  ? Colors.white
                                  : ColorConfig.textBlack,
                            ),
                          ),
                          FilterChip(
                            label: const Text('Nữ'),
                            selected: tempSelectedGender == 'female',
                            onSelected: (selected) {
                              setModalState(() {
                                tempSelectedGender =
                                selected ? 'female' : null;
                              });
                            },
                            selectedColor: ColorConfig.primary.withOpacity(1),
                            backgroundColor: const Color(0xFFF9F5F0),
                            checkmarkColor: ColorConfig.white,
                            labelStyle: TextStyle(
                              color: tempSelectedGender == 'female'
                                  ? Colors.white
                                  : ColorConfig.textBlack,
                            ),
                          ),
                          FilterChip(
                            label: const Text('Khác'),
                            selected: tempSelectedGender == 'other',
                            onSelected: (selected) {
                              setModalState(() {
                                tempSelectedGender =
                                selected ? 'other' : null;
                              });
                            },
                            selectedColor: ColorConfig.primary.withOpacity(1),
                            backgroundColor: const Color(0xFFF9F5F0),
                            checkmarkColor: ColorConfig.white,
                            labelStyle: TextStyle(
                              color: tempSelectedGender == 'other'
                                  ? Colors.white
                                  : ColorConfig.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                                color: Color(0xFF000000)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: Text(
                            'Hủy',
                            style: TextStyle(
                              color: ColorConfig.textBlack,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedGender = tempSelectedGender;
                            });
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConfig.primary,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom sheet lọc riêng theo dịch vụ
  void _showServiceFilterBottomSheet(BuildContext context) {
    String? tempSelectedServiceId = selectedServiceId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Loại dịch vụ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ColorConfig.textBlack,
                        ),
                      ),
                      if (tempSelectedServiceId != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempSelectedServiceId = null;
                            });
                          },
                          child: Text(
                            'Xóa',
                            style: TextStyle(
                              color: ColorConfig.textBlack,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Service list as selectable chips
                  if (services.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // "Tất cả" option
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempSelectedServiceId = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: tempSelectedServiceId == null
                                  ? ColorConfig.primary
                                  : const Color(0xFFF9F5F0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: tempSelectedServiceId == null
                                    ? ColorConfig.primary
                                    : ColorConfig.primary,
                              ),
                            ),
                            child: Text(
                              'Tất cả',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: tempSelectedServiceId == null
                                    ? Colors.white
                                    : ColorConfig.textBlack,
                              ),
                            ),
                          ),
                        ),
                        ...services.map((service) {
                          final isSelected =
                              tempSelectedServiceId == service['_id'];
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                tempSelectedServiceId =
                                isSelected ? null : service['_id'];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorConfig.primary
                                    : const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? ColorConfig.primary
                                      : const Color(0xFFACACAC),
                                ),
                              ),
                              child: Text(
                                service['name'] ?? 'Không tên',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : ColorConfig.textBlack,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: ColorConfig.black.withOpacity(.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: Text(
                            'Hủy',
                            style: TextStyle(
                              color: ColorConfig.textBlack,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedServiceId = tempSelectedServiceId;
                            });
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConfig.primary,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String? displayAddress;

    if (addressCustomer == null ||
        addressCustomer is! String ||
        addressCustomer!.trim().isEmpty) {
      displayAddress = 'Chưa có vị trí';
    } else {
      displayAddress = addressCustomer;
    }

    return Scaffold(
      backgroundColor: ColorConfig.greyListTechnician,
      appBar: PreferredSize(
        preferredSize: const ui.Size.fromHeight(110),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: ColorConfig.greyListTechnician,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
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

                      const SizedBox(width: 8),

                      Expanded(
                        flex: 2,
                        child: Text(
                          displayAddress ?? "Chưa có vị trí",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 40,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Tìm kiếm...",
                              hintStyle: TextStyle(
                                color:
                                ColorConfig.black.withOpacity(0.6),
                              ),
                              isDense: true,
                              contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              prefixIcon: Icon(Icons.search,
                                  color: ColorConfig.black, size: 20),
                              prefixIconConstraints: const BoxConstraints(
                                minHeight: 40,
                                minWidth: 40,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: () {
                          context.go(CustomerRouterConfig.listLike);
                        },
                        child: Container(
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

                  const SizedBox(height: 12),

                  // ===== HÀNG DƯỚI (Filter chips) =====
                  Row(
                    children: [
                      // Filter button với red dot khi có filter giới tính active
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 37,
                            height: 37,
                            decoration: BoxDecoration(
                              color: ColorConfig.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.filter_list,
                                  color: ColorConfig.black, size: 20),
                              onPressed: () =>
                                  _showFilterBottomSheet(context),
                            ),
                          ),
                          // Red dot indicator chỉ cho filter giới tính
                          if (_hasActiveFilter)
                            Positioned(
                              top: -2,
                              right: -2,
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

                      const SizedBox(width: 10),

                      // Gần tôi chip
                      _buildChip(
                        label: "Gần tôi",
                        icon: Icons.location_on_outlined,
                        isActive: false,
                        onTap: () {
                          // xử lý gần tôi
                        },
                      ),

                      const SizedBox(width: 10),

                      // Loại dịch vụ chip - hiển thị tên dịch vụ đã chọn, không có red dot
                      _buildChip(
                        label: _getSelectedServiceLabel(),
                        icon: Icons.keyboard_arrow_down_rounded,
                        isActive: _hasActiveServiceFilter,
                        onTap: () {
                          _showServiceFilterBottomSheet(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: ColorConfig.primary,
        ),
      )
          : (errorMessage != null)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: ColorConfig.textBlack,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _loadData(); // Thử tải lại
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConfig.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : (filteredTechnicians.isEmpty)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 60,
              color: ColorConfig.black.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có kỹ thuật viên nào', // Đã sửa theo yêu cầu
              style: TextStyle(
                color: ColorConfig.textBlack,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
              style: TextStyle(
                color: ColorConfig.textBlack.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(
            vertical: 2, horizontal: 5),
        itemCount: filteredTechnicians.length,
        itemBuilder: (context, index) {
          final tech = filteredTechnicians[index];

          final rate = tech['rate'];
          final reviewCount = tech['reviewCount'];
          final hasReview =
              reviewCount != null && reviewCount > 0;
          final displayRate = hasReview
              ? rate?.toStringAsFixed(1) ?? '5.0'
              : '5.0';

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // context.go(
              //   '/home-customer/list-technician/detail-technician/${tech['_id']}',
              // );
              context.push(
                '${CustomerRouterConfig.detailOrderNowTechnician}/${tech['_id']}',
                extra: 'now',
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(
                  vertical: 2, horizontal: 5),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(10),
                      border: Border.all(
                          color: ColorConfig.primary,
                          width: 0),
                    ),
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(8),
                      child: tech['avatar'] != null &&
                          tech['avatar']['url'] != null
                          ? Image.network(
                        FormatHelper
                            .formatNetworkImageUrl(
                            tech['avatar']['url']),
                        fit: BoxFit.cover,
                      )
                          : Container(
                        color: ColorConfig.primary,
                        child: Icon(
                          Icons.person,
                          color:
                          ColorConfig.textBlack,
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          FormatHelper
                              .formatNameTechnician(
                              tech['fullName'] ??
                                  'Không tên'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ColorConfig.textBlack,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.solidStar,
                              size: 14,
                              color: ColorConfig.yellow
                                  .withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasReview
                                  ? '$displayRate ($reviewCount đánh giá)'
                                  : displayRate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ColorConfig.textBlack
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.locationArrow,
                              size: 16,
                              color: ColorConfig.black
                                  .withOpacity(0.4),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tech['distance'] != null
                                    ? '${tech['distance']} km'
                                    : '-- km',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorConfig
                                      .textBlack
                                      .withOpacity(0.4),
                                ),
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),
                  InkWell(
                    borderRadius:
                    BorderRadius.circular(20),
                    onTap: () {
                      context.push(
                        '${CustomerRouterConfig.detailOrderNowTechnician}/${tech['_id']}',
                        extra: 'now',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConfig.primary,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Đặt",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? ColorConfig.primary.withOpacity(0.15)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: ColorConfig.primary, width: 1)
              : Border.all(color: ColorConfig.primary, width: .2),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? ColorConfig.primary
                    : ColorConfig.black,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon,
                size: 16,
                color: isActive
                    ? ColorConfig.primary
                    : ColorConfig.black),
          ],
        ),
      ),
    );
  }
}