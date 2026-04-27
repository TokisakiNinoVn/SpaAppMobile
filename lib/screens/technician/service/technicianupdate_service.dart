import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/service_service.dart';
import '../../../helper/snackbar_helper.dart';

class TechnicianUpdateService extends StatefulWidget {
  const TechnicianUpdateService({super.key});

  @override
  State<TechnicianUpdateService> createState() => _TechnicianUpdateServiceState();
}

class _TechnicianUpdateServiceState extends State<TechnicianUpdateService> {
  final ServiceService _serviceService = ServiceService();

  final _formKey = GlobalKey<FormState>();
  List<dynamic>? serviceIds = [];
  List<dynamic>? allServices = [];
  List<dynamic>? originalServiceIds = []; // Lưu trữ danh sách gốc
  Map<String, dynamic>? selectedServiceDetail;
  bool _showDetailPopup = false;
  bool _hasChanges = false; // Biến kiểm tra có thay đổi không

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadServiceIds();
      await _loadAllServices();
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadServiceIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('serviceIds');

    if (jsonString != null) {
      setState(() {
        serviceIds = List<String>.from(jsonDecode(jsonString));
        originalServiceIds = List<String>.from(jsonDecode(jsonString));
      });
      print("Loaded serviceIds: ${serviceIds}");
    } else {
      // Fallback: Try to get from response data if available
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        if (userData['data']?['technicianProfile']?['serviceIds'] != null) {
          setState(() {
            serviceIds = List<String>.from(userData['data']['technicianProfile']['serviceIds']);
            originalServiceIds = List<String>.from(userData['data']['technicianProfile']['serviceIds']);
          });
        }
      }
    }
  }

  Future<void> _loadAllServices() async {
    try {
      final response = await _serviceService.listService();
      setState(() {
        allServices = response['data'];
      });
    } catch (e) {
      print("Error loading services: $e");
    }
  }

  bool _isServiceSelected(String serviceId) {
    return serviceIds?.contains(serviceId) ?? false;
  }

  void _toggleServiceSelection(String serviceId) {
    setState(() {
      if (_isServiceSelected(serviceId)) {
        serviceIds?.remove(serviceId);
      } else {
        serviceIds?.add(serviceId);
      }
      _checkForChanges();
    });
    // Không tự động lưu ở đây nữa, chỉ lưu khi nhấn nút "Lưu thay đổi"
  }

  void _checkForChanges() {
    // So sánh danh sách hiện tại với danh sách gốc
    bool hasChanges = false;

    if (serviceIds == null && originalServiceIds == null) {
      hasChanges = false;
    } else if (serviceIds == null || originalServiceIds == null) {
      hasChanges = true;
    } else if (serviceIds!.length != originalServiceIds!.length) {
      hasChanges = true;
    } else {
      // Sắp xếp và so sánh từng phần tử
      final sortedCurrent = List<String>.from(serviceIds!)..sort();
      final sortedOriginal = List<String>.from(originalServiceIds!)..sort();

      for (int i = 0; i < sortedCurrent.length; i++) {
        if (sortedCurrent[i] != sortedOriginal[i]) {
          hasChanges = true;
          break;
        }
      }
    }

    setState(() {
      _hasChanges = hasChanges;
    });
  }

  Future<void> _saveServiceIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serviceIds', jsonEncode(serviceIds));
  }

  void _showServiceDetail(Map<String, dynamic> service) {
    setState(() {
      selectedServiceDetail = service;
      _showDetailPopup = true;
    });
  }

  void _hideServiceDetail() {
    setState(() {
      _showDetailPopup = false;
      selectedServiceDetail = null;
    });
  }

  Future<void> _updateServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // SỬA LỖI: Lấy danh sách serviceIds hiện tại (đã thay đổi)
      final List<String> currentServiceIds = List<String>.from(serviceIds ?? []);

      final payload = {
        "serviceIds": currentServiceIds,
      };

      await _serviceService.technicianAddService(payload);

      // Cập nhật lại originalServiceIds với giá trị mới
      setState(() {
        originalServiceIds = List<String>.from(currentServiceIds);
        _hasChanges = false;
      });

      // Lưu vào shared_preferences
      await _saveServiceIds();

      SnackBarHelper.showSuccess(
        context,
        'Cập nhật dịch vụ thành công!',
      );

      context.pop();
    } catch (e) {
      SnackBarHelper.showError(
        context,
        'Có lỗi xảy ra: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final isSelected = _isServiceSelected(service['_id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConfig.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? ColorConfig.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox
          Transform.scale(
            scale: 1.3,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) {
                _toggleServiceSelection(service['_id']);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              activeColor: ColorConfig.primary,
            ),
          ),

          const SizedBox(width: 12),

          // Service Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? ColorConfig.primary : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? 'Không có mô tả',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Detail Button
          IconButton(
            onPressed: () => _showServiceDetail(service),
            icon: Icon(
              Icons.info_outline,
              color: ColorConfig.primary,
            ),
            tooltip: 'Xem chi tiết',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPopup() {
    if (selectedServiceDetail == null) return const SizedBox();

    final service = selectedServiceDetail!;
    final timePrices = service['timePrices'] as List? ?? [];
    final isSelected = _isServiceSelected(service['_id']);

    // SỬA LỖI: Thêm AnimatedPositioned để popup hiển thị từ dưới lên
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: _showDetailPopup ? 0 : -500, // Ẩn popup bằng cách đưa ra ngoài màn hình
      left: 0,
      right: 0,
      child: Container(
        height: 450,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi tiết dịch vụ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorConfig.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: _hideServiceDetail,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Service name
              Text(
                service['name'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                service['description'] ?? 'Không có mô tả',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 16),

              // Divider
              Divider(color: Colors.grey.shade300),

              // Time and Price section
              const Text(
                'Thời gian & Giá cả',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              if (timePrices.isEmpty)
                Text(
                  'Chưa có thông tin giá',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ...timePrices.map((priceInfo) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: ColorConfig.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${priceInfo['duration']} ${priceInfo['unit'] ?? 'phút'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${priceInfo['price']?.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},') ?? '0'} VNĐ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorConfig.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _toggleServiceSelection(service['_id']);
                        if (isSelected) {
                          _hideServiceDetail();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isSelected ? Colors.red : ColorConfig.primary,
                        side: BorderSide(
                          color: isSelected ? Colors.red : ColorConfig.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(isSelected ? 'Bỏ chọn dịch vụ này' : 'Chọn dịch vụ này'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    if (!_hasChanges) return const SizedBox();

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _updateServices,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConfig.primary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.save,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'Lưu thay đổi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangesIndicator() {
    if (!_hasChanges) return const SizedBox();

    return Positioned(
      bottom: 80, // Đặt phía trên nút Lưu
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border(
            top: BorderSide(color: Colors.orange.shade200),
            bottom: BorderSide(color: Colors.orange.shade200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info,
              color: Colors.orange.shade700,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Bạn có thay đổi chưa lưu',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Chỉnh sửa dịch vụ của bạn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_hasChanges) {
              // Hiển thị cảnh báo nếu có thay đổi chưa lưu
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Thay đổi chưa lưu'),
                  content: const Text('Bạn có thay đổi chưa lưu. Bạn có muốn thoát mà không lưu?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ở lại'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Đóng dialog
                        context.pop(); // Quay lại màn hình trước
                      },
                      child: const Text('Thoát'),
                    ),
                  ],
                ),
              );
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: ColorConfig.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorConfig.primary),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ColorConfig.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chọn các dịch vụ bạn có thể cung cấp. Nhấn vào biểu tượng ℹ️ để xem chi tiết.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isLoading && allServices!.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Services list
                if (!_isLoading && allServices!.isNotEmpty)
                  ...allServices!.map((service) => _buildServiceItem(service)).toList(),

                // Empty state
                if (allServices!.isEmpty && !_isLoading)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        Icon(
                          Icons.miscellaneous_services,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có dịch vụ nào',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),

          _buildChangesIndicator(),

          _buildSaveButton(),

          _buildDetailPopup(),
        ],
      ),
    );
  }
}