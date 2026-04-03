import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spa_app/helper/location_helper.dart';

import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/services/service_service.dart';
import 'package:spa_app/utils/address_util.dart';

class ListTechnicianScreen extends StatefulWidget {
  const ListTechnicianScreen({super.key});

  @override
  State<ListTechnicianScreen> createState() => _ListTechnicianScreenState();
}

class _ListTechnicianScreenState extends State<ListTechnicianScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final ServiceService _serviceService = ServiceService();
  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> filteredTechnicians = [];
  List<Map<String, dynamic>> services = [];

  // Filter states
  String? selectedGender;
  String? addressCustomer = "Chưa có vị trí";
  Double? latValue;
  Double? longValue;
  String? selectedServiceId;
  String searchQuery = '';

  // Loading state
  bool isLoading = true;
  bool checkPermissionLocation = true;
  double? currentLat;
  double? currentLng;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _loadListService();
      if(checkPermissionLocation) {
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
    // final location = await LocationHelper.getCurrentLocation();
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
      if(checkPermissionLocation) {
        response = await _technicianService.getListTechnicianForCustomer(currentLat, currentLng);
      } else {
        response = await _technicianService.getListTechnicianForCustomer(null, null);
      }
      if (response['success'] == true) {
        setState(() {
          technicians = List<Map<String, dynamic>>.from(response['data'] ?? []);
          filteredTechnicians = List.from(technicians);
        });
      } else {
        print("============== Else ==================");
      }
    } catch (e) {
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
          final techServices = List<Map<String, dynamic>>.from(tech['service'] ?? []);
          final hasService = techServices.any((service) => service['_id'] == selectedServiceId);
          if (!hasService) {
            return false;
          }
        }

        // Filter by search query
        if (searchQuery.isNotEmpty) {
          final fullName = tech['fullName']?.toString().toLowerCase() ?? '';
          final province = tech['province']?.toString().toLowerCase() ?? '';
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

  void _showFilterBottomSheet(BuildContext context) {
    String? tempSelectedGender = selectedGender;
    String? tempSelectedServiceId = selectedServiceId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                          color: const Color(0xFF5D4037),
                        ),
                      ),
                      if (tempSelectedGender != null || tempSelectedServiceId != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelectedGender = null;
                              tempSelectedServiceId = null;
                            });
                          },
                          child: Text(
                            'Xóa bộ lọc',
                            style: TextStyle(
                              color: const Color(0xFFB08D57),
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
                          color: const Color(0xFF8D6E63),
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
                              setState(() {
                                tempSelectedGender = selected ? 'male' : null;
                              });
                            },
                            selectedColor: const Color(0xFFD4A574),
                            backgroundColor: const Color(0xFFF9F5F0),
                            labelStyle: TextStyle(
                              color: tempSelectedGender == 'male' ? Colors.white : const Color(0xFF5D4037),
                            ),
                          ),
                          FilterChip(
                            label: const Text('Nữ'),
                            selected: tempSelectedGender == 'female',
                            onSelected: (selected) {
                              setState(() {
                                tempSelectedGender = selected ? 'female' : null;
                              });
                            },
                            selectedColor: const Color(0xFFD4A574),
                            backgroundColor: const Color(0xFFF9F5F0),
                            labelStyle: TextStyle(
                              color: tempSelectedGender == 'female' ? Colors.white : const Color(0xFF5D4037),
                            ),
                          ),
                          FilterChip(
                            label: const Text('Khác'),
                            selected: tempSelectedGender == 'other',
                            onSelected: (selected) {
                              setState(() {
                                tempSelectedGender = selected ? 'other' : null;
                              });
                            },
                            selectedColor: const Color(0xFFD4A574),
                            backgroundColor: const Color(0xFFF9F5F0),
                            labelStyle: TextStyle(
                              color: tempSelectedGender == 'other' ? Colors.white : const Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Service filter
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dịch vụ',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF8D6E63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (services.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: tempSelectedServiceId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE8D8C3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE8D8C3)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9F5F0),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Tất cả dịch vụ',
                                style: TextStyle(color: Color(0xFF8D6E63)),
                              ),
                            ),
                            ...services.map((service) {
                              return DropdownMenuItem<String>(
                                value: service['_id'] as String,
                                child: Text(
                                  service['name'] ?? 'Không tên',
                                  style: const TextStyle(color: Color(0xFF5D4037)),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              tempSelectedServiceId = value;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFB08D57)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Hủy',
                            style: TextStyle(
                              color: const Color(0xFFB08D57),
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
                              selectedServiceId = tempSelectedServiceId;
                            });
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A574),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
    const Color spaPrimaryColor = Color(0xFFD4A574);
    const Color spaSecondaryColor = Color(0xFFB08D57);
    const Color spaBackgroundColor = Color(0xFFF9F5F0);
    const Color spaTextColor = Color(0xFF5D4037);
    const Color spaDividerColor = Color(0xFFE8D8C3);
    const Color spaLightTextColor = Color(0xFF8D6E63);
    String? displayAddress;

    if (addressCustomer == null ||
        addressCustomer is! String ||
        addressCustomer!.trim().isEmpty) {
      displayAddress = 'Chưa có vị trí';
    } else {
      displayAddress = addressCustomer;
    }

    return Scaffold(
      backgroundColor: spaBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const ui.Size.fromHeight(110),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: spaBackgroundColor,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            displayAddress ?? "Chưa có vị trí",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: spaDividerColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_back, color: spaTextColor),
                            ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.favorite, color: spaSecondaryColor),
                            tooltip: 'Yêu thích',
                            onPressed: () {
                              context.go('/home-customer/list-technician/list-like-technician');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 10),

                  // ===== HÀNG DƯỚI =====
                  Row(
                    children: [
                      // Nút lọc
                      IconButton(
                        icon: Icon(Icons.filter_list, color: spaSecondaryColor),
                        tooltip: 'Lọc',
                        onPressed: () => _showFilterBottomSheet(context),
                      ),

                      const SizedBox(width: 8),

                      // Thanh tìm kiếm
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: spaDividerColor, width: 1),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Tìm kiếm...",
                              hintStyle: TextStyle(
                                color: spaTextColor.withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: spaSecondaryColor),
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD4A574),
        ),
      )
          : Column(
        children: [
          // Active filters display
          if (selectedGender != null || selectedServiceId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.filter_alt, color: spaSecondaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (selectedGender != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: spaDividerColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    selectedGender == 'male' ? 'Nam' :
                                    selectedGender == 'female' ? 'Nữ' : 'Khác',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: spaTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedGender = null;
                                      });
                                      _applyFilters();
                                    },
                                    child: Icon(Icons.close, size: 16, color: spaTextColor),
                                  ),
                                ],
                              ),
                            ),
                          if (selectedServiceId != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: spaDividerColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    services.firstWhere(
                                          (s) => s['_id'] == selectedServiceId,
                                      orElse: () => {'name': 'Dịch vụ'},
                                    )['name'] ?? 'Dịch vụ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: spaTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedServiceId = null;
                                      });
                                      _applyFilters();
                                    },
                                    child: Icon(Icons.close, size: 16, color: spaTextColor),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedGender != null || selectedServiceId != null)
                    TextButton(
                      onPressed: _clearFilters,
                      child: Text(
                        'Xóa bộ lọc',
                        style: TextStyle(
                          color: spaSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          Expanded(
            child: filteredTechnicians.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 60,
                    color: spaLightTextColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy kỹ thuật viên nào',
                    style: TextStyle(
                      color: spaLightTextColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
                    style: TextStyle(
                      color: spaLightTextColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
              itemCount: filteredTechnicians.length,
              itemBuilder: (context, index) {

                final tech = filteredTechnicians[index];

                final rate = tech['rate'];
                final reviewCount = tech['reviewCount'];
                final hasReview = reviewCount != null && reviewCount > 0;
                final displayRate = hasReview
                    ? rate?.toStringAsFixed(1) ?? '5.0'
                    : '5.0';

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context.go(
                      '/home-customer/list-technician/detail-technician/${tech['_id']}',
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: spaDividerColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: spaDividerColor, width: 0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: tech['avatar'] != null && tech['avatar']['url'] != null
                                ? Image.network(
                              FormatHelper.formatNetworkImageUrl(tech['avatar']['url']),
                              fit: BoxFit.cover,
                            )
                                : Container(
                              color: spaDividerColor,
                              child: Icon(
                                Icons.person,
                                color: spaLightTextColor,
                                size: 40,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FormatHelper.formatNameTechnician(
                                    tech['fullName'] ?? 'Không tên'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: spaTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  Icon(Icons.star, color: spaSecondaryColor, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    hasReview
                                        ? '$displayRate ($reviewCount đánh giá)'
                                        : displayRate,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: spaSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: spaLightTextColor, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      tech['distance'] != null
                                          ? '${tech['distance']} km'
                                          : '-- km',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: spaLightTextColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            context.go(
                              '/home-customer/list-technician/detail-technician/${tech['_id']}',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                    horizontal:12,
                                    vertical: 4,
                                  ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A574),
                              borderRadius: BorderRadius.circular(20),
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


                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}