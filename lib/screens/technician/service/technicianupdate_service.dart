import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/providers/service_provider.dart';
import 'package:spa_app/services/service_service.dart';
import '../../../helper/snackbar_helper.dart';

class TechnicianUpdateService extends StatefulWidget {
  const TechnicianUpdateService({super.key});

  @override
  State<TechnicianUpdateService> createState() => _TechnicianUpdateServiceState();
}

class _TechnicianUpdateServiceState extends State<TechnicianUpdateService> {
  final ServiceService _serviceService = ServiceService();

  List<String> serviceIds = [];
  List<String> originalServiceIds = [];
  Map<String, dynamic>? selectedServiceDetail;
  List<Map<String, dynamic>> allServices = [];

  bool _showDetailPopup = false;
  bool _hasChanges = false;
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadServiceIds();
      });
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
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final success = await serviceProvider.loadSelectedServices();

    if (!success) {
      appLog(
        "Load selected services failed: ${serviceProvider.errorMessage}",
      );
      return;
    }

    final services = serviceProvider.selectedServices;

    final loadedIds = services
        .map<String>((service) => service['_id'].toString())
        .toList();

    setState(() {
      serviceIds = loadedIds;
      originalServiceIds = List<String>.from(loadedIds);
    });

    // appLog("Loaded serviceIds: $serviceIds");
  }

  Future<void> _loadAllServices() async {
    try {
      final response = await _serviceService.listService();
      // appLog("response: $response");

      setState(() {
        allServices =
        List<Map<String, dynamic>>.from(response['data'] ?? []);
      });
    } catch (e) {
      appLog("Error loading services: $e");
    }
  }

  bool _isServiceSelected(String serviceId) {
    return serviceIds.contains(serviceId);
  }

  void _toggleServiceSelection(String serviceId) {
    setState(() {
      if (serviceIds.contains(serviceId)) {
        serviceIds.remove(serviceId);
      } else {
        serviceIds.add(serviceId);
      }

      _checkForChanges();
    });
  }

  void _checkForChanges() {
    final current = [...serviceIds]..sort();
    final original = [...originalServiceIds]..sort();

    final hasChanges = current.length != original.length ||
        !current.asMap().entries.every(
              (entry) => entry.value == original[entry.key],
        );

    setState(() {
      _hasChanges = hasChanges;
    });
  }

  // Future<void> _saveServiceIds() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('serviceIds', jsonEncode(serviceIds));
  // }

  Future<void> _updateServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> currentServiceIds = List<String>.from(serviceIds ?? []);

      final body = {
        "serviceIds": currentServiceIds,
      };

      await _serviceService.technicianUpdateService(body);

      setState(() {
        originalServiceIds = List<String>.from(currentServiceIds);
        _hasChanges = false;
      });

      // await _saveServiceIds();

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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: ColorConfig.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? ColorConfig.primary : Colors.grey.shade300,
          width: isSelected ? 0.5 : 0.1,
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
          IconButton(
            onPressed: () {
              selectedServiceDetail = service;
              _showServiceDetailBottomSheet(context);
            },
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

  void _showServiceDetailBottomSheet(BuildContext context) {
    if (selectedServiceDetail == null) return;

    final service = selectedServiceDetail!;
    final timePrices = service['timePrices'] as List? ?? [];
    final isSelected = _isServiceSelected(service['_id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chi tiết dịch vụ',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: ColorConfig.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      service['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              service['description'] ?? 'Không có mô tả',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: ColorConfig.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Thời gian & Giá cả',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (timePrices.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Chưa có thông tin giá',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            ...timePrices.map((priceInfo) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.grey.shade50,
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: ColorConfig.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.access_time_rounded,
                                        color: ColorConfig.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${priceInfo['duration']} ${priceInfo['unit'] ?? 'phút'}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Thời lượng dịch vụ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "${FormatHelper.formatPrice(priceInfo['price'])} VNĐ",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConfig.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _toggleServiceSelection(service['_id']);
                                if (isSelected) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Colors.red
                                    : ColorConfig.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(
                                isSelected
                                    ? 'Bỏ chọn dịch vụ này'
                                    : 'Chọn dịch vụ này',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn có thay đổi chưa lưu',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateServices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Chỉnh sửa dịch vụ cung cấp",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: ColorConfig.primaryBackground   ,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (_isLoading && allServices.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (!_isLoading && allServices.isNotEmpty)
                      ...allServices.map((service) => _buildServiceItem(service)).toList(),
                    if (allServices.isEmpty && !_isLoading)
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
                  ],
                ),
              ),
            ),
            if (_hasChanges) _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }
}