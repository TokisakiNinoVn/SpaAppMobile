import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/technician_router_config.dart';
import 'package:spa_app/screens/customer/tabs/components/SpaDialog.dart';
import 'package:spa_app/screens/technician/tabs/components/accept_order_dialog.dart';
import 'package:spa_app/screens/technician/tabs/components/job_card_get_job.dart';
import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/services/realtime_service.dart';
import 'package:spa_app/services/service_service.dart';
import 'dart:async';

import '../../../storage/index.dart';

class JobApplicationTab extends StatefulWidget {
  const JobApplicationTab({super.key});

  @override
  State<JobApplicationTab> createState() => _JobApplicationTabState();
}

class _JobApplicationTabState extends State<JobApplicationTab> {
  final OrderService _orderService = OrderService();
  late RealtimeService _realtimeService;
  final ServiceService _serviceService = ServiceService();

  bool _isLoading = true;
  bool _isLogin = false;
  String _errorMessage = '';
  bool isWorking = false;
  final Map<String, Timer> _timers = {};
  Timer? _countdownTimer;

  List<dynamic> listJobs = [];
  List<dynamic> filteredJobs = [];
  Map<String, Duration> _remainingTimes = {};
  List<dynamic>? allServices = [];

  // Filter variables
  String _selectedServiceId = 'all';
  String _selectedTimeFilter = 'all'; // 'all', '60', '90', '120'
  String _searchAddress = '';
  int _totalJobs = 0;
  // Thêm biến tạm để lưu giá trị đang chọn trong bottom sheet
  String _tempServiceId = 'all';
  String _tempTimeFilter = 'all';

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllServices();
    _loadBookOrders();
    _startCountdownTimer();

    _realtimeService = RealtimeService(
      onOrderRemoved: (orderId) {
        if (!mounted) return;
        setState(() {
          listJobs.removeWhere((e) => e['_id'] == orderId);
          _remainingTimes.remove(orderId);
          _applyFilter();
        });
      },
      onNewOrderAutoMatching: _handleNewOrder,
    );

    _realtimeService.connect();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleNewOrder(Map<String, dynamic> order) {
    if (isWorking) return;

    final actualOrder = order['data'] ?? order;
    final orderId = actualOrder['_id'];

    if (listJobs.any((o) => o['_id'] == orderId)) return;

    final expiresAtStr = actualOrder['expiresAt'];
    if (expiresAtStr != null && expiresAtStr is String) {
      final expiryTime = DateTime.parse(expiresAtStr);
      if (expiryTime.isBefore(DateTime.now())) return;
    }

    Duration? initialRemaining;
    if (expiresAtStr != null && expiresAtStr is String) {
      final expiryTime = DateTime.parse(expiresAtStr);
      final now = DateTime.now();
      if (expiryTime.isAfter(now)) {
        initialRemaining = expiryTime.difference(now);
      }
    }

    Future.microtask(() {
      if (mounted) {
        setState(() {
          listJobs.insert(0, actualOrder);
          if (initialRemaining != null && initialRemaining.inSeconds > 0) {
            _remainingTimes[orderId] = initialRemaining;
          }
        });
        _startTimerForSingleOrder(actualOrder);
        _applyFilter();
      }
    });
  }

  void _applyFilter() {
    final now = DateTime.now();
    final newFiltered = listJobs.where((job) {
      // Filter by service
      if (_selectedServiceId != 'all' && job['serviceId'] != _selectedServiceId) {
        return false;
      }

      // Filter by address
      if (_searchAddress.isNotEmpty) {
        final address = (job['address'] ?? '').toString().toLowerCase();
        final searchLower = _searchAddress.toLowerCase();
        if (!address.contains(searchLower)) {
          return false;
        }
      }

      // Filter by time (based on service duration)
      if (_selectedTimeFilter != 'all') {
        final serviceDuration = job['serviceDuration'] ?? 0;
        final maxDuration = int.parse(_selectedTimeFilter);
        if (serviceDuration > maxDuration) {
          return false;
        }
      }

      // Filter expired orders
      final expiresAtStr = job['expiresAt'];
      if (expiresAtStr != null && expiresAtStr is String) {
        final expiryTime = DateTime.parse(expiresAtStr);
        if (expiryTime.isBefore(now)) return false;
      }
      return true;
    }).toList();

    if (mounted) {
      setState(() {
        filteredJobs = newFiltered;
      });
    }
  }

  void _startTimerForSingleOrder(dynamic order) {
    final expiresAt = order['expiresAt'];
    final orderId = order['_id'];

    if (expiresAt != null && expiresAt is String) {
      final expiryTime = DateTime.parse(expiresAt);
      final now = DateTime.now();

      if (expiryTime.isAfter(now)) {
        final remaining = expiryTime.difference(now);
        if (mounted) {
          setState(() {
            _remainingTimes[orderId] = remaining;
          });
        }

        final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          final currentRemaining = expiryTime.difference(DateTime.now());
          if (currentRemaining.isNegative) {
            timer.cancel();
            _timers.remove(orderId);
            if (mounted) {
              setState(() {
                _remainingTimes.remove(orderId);
                listJobs.removeWhere((e) => e['_id'] == orderId);
                _applyFilter();
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _remainingTimes[orderId] = currentRemaining;
              });
            }
          }
        });
        _timers[orderId] = timer;
      }
    }
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    _realtimeService.disconnect();
    _countdownTimer?.cancel();
    _searchController.dispose();
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateRemainingTimes();
        _removeExpiredOrders();
      }
    });
  }

  void _updateRemainingTimes() {
    final now = DateTime.now();
    bool hasChanges = false;

    for (var job in listJobs) {
      final orderId = job['_id'];
      final expiresAtStr = job['expiresAt'];
      if (expiresAtStr == null || expiresAtStr is! String) continue;
      final expiryTime = DateTime.parse(expiresAtStr);
      final remaining = expiryTime.difference(now);

      if (remaining.isNegative) {
        if (_remainingTimes.containsKey(orderId)) {
          _remainingTimes.remove(orderId);
          hasChanges = true;
        }
      } else {
        if (_remainingTimes[orderId] != remaining) {
          _remainingTimes[orderId] = remaining;
          hasChanges = true;
        }
      }
    }

    if (hasChanges && mounted) {
      setState(() {});
    }
  }

  void _removeExpiredOrders() {
    final now = DateTime.now();
    bool changed = false;
    final toRemove = <String>[];

    for (var job in listJobs) {
      final expiresAtStr = job['expiresAt'];
      if (expiresAtStr == null || expiresAtStr is! String) continue;
      final expiryTime = DateTime.parse(expiresAtStr);
      if (expiryTime.isBefore(now)) {
        toRemove.add(job['_id']);
      }
    }

    if (toRemove.isNotEmpty) {
      setState(() {
        listJobs.removeWhere((job) => toRemove.contains(job['_id']));
        for (var id in toRemove) {
          _remainingTimes.remove(id);
        }
        changed = true;
      });
      if (changed) _applyFilter();
    }
  }

  Future<void> _loadAllServices() async {
    isWorking = await SharedPrefs.getValue(PrefType.bool, "isWorking") ?? false;

    try {
      final response = await _serviceService.listService();
      setState(() {
        allServices = response['data'];
      });
    } catch (e) {
      appLog("Error loading services: $e");
    }
  }

  Future<void> _loadBookOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final queryParams = 'status=pending&typeOrder=automatic-matching&timeRange=2d';
      final response = await _orderService.listFilterOrder(queryParams);

      if (response['success'] == true) {
        final newOrders = response['data'] ?? [];
        final now = DateTime.now();

        final validOrders = newOrders.where((job) {
          final expiresAtStr = job['expiresAt'];
          if (expiresAtStr == null || expiresAtStr is! String) return true;
          final expiryTime = DateTime.parse(expiresAtStr);
          return expiryTime.isAfter(now);
        }).toList();

        setState(() {
          listJobs = List.from(validOrders);
          _totalJobs = listJobs.length;
          _isLoading = false;
          _remainingTimes.clear();
          for (var job in listJobs) {
            final expiresAtStr = job['expiresAt'];
            if (expiresAtStr != null && expiresAtStr is String) {
              final expiryTime = DateTime.parse(expiresAtStr);
              final remaining = expiryTime.difference(now);
              if (remaining.inSeconds > 0) {
                _remainingTimes[job['_id']] = remaining;
              }
            }
          }
          _applyFilter();
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải danh sách đơn đặt trước');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      appLog('Error loading book orders: $e');
    }
  }

  void _acceptJob(Map<String, dynamic> job) {
    bool isAdminCreate = job['isAdminCreate'] ?? false;
    if (isAdminCreate) {
      _showConfirmApplyJobDialog();
      return;
    }
    SnackBarHelper.showWarning(context, 'Chức năng đang phát triển!');
  }

  Future<void> _acceptOrderWithMessage(Map<String, dynamic> order, String message) async {
    try {
      final idOrder = order["_id"];
      if (order['typeOrder'] == 'order-now') {
        final data = {
          'orderId': idOrder,
          'result': 'approved',
          'noteTechnician': message,
        };

        final response = await _orderService.updateStatus(data);
        if (response['success'] == true) {
          if (!mounted) return;
          final acceptedAt = DateTime.now().toIso8601String();
          await SharedPrefs.saveValue(PrefType.string, "orderDetail", order);
          await SharedPrefs.saveValue(PrefType.bool, "isWorking", true);
          await SharedPrefs.saveValue(PrefType.string, "idOrderWorking", idOrder);
          await SharedPrefs.saveValue(PrefType.string, "acceptedAt", acceptedAt);
          SnackBarHelper.showSuccess(context, "Nhận đơn thành công!");
          context.go(TechnicianRouterConfig.homeTechnician);
        }
      } else if (order['typeOrder'] == 'book') {
        final data = {
          'orderId': idOrder,
          'result': 'approved'
        };
        final response = await _orderService.updateStatus(data);
        if (response['success'] == true) {
          if (!mounted) return;
          SnackBarHelper.showSuccess(context, "Nhận đơn việc đặt trước thành công!");
          setState(() {
            listJobs.removeWhere((e) => e['_id'] == idOrder);
            _remainingTimes.remove(idOrder);
            _applyFilter();
          });
        } else {
          SnackBarHelper.showError(context, "Lỗi khi nhận đơn!");
        }
      } else {
        SnackBarHelper.showError(context, "Không rõ loại đơn!");
      }
    } catch (e) {
      debugPrint('Error accepting order: $e');
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Có lỗi xảy ra khi nhận đơn');
    }
  }

  Future<void> showAcceptOrderDialog({
    required BuildContext context,
    required Map<String, dynamic> order,
    required Future<void> Function(String message) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) {
        return AcceptOrderDialog(
          onConfirm: (message) async {
            await _acceptOrderWithMessage(order, message);
          },
        );
      },
    );
  }

  Future<void> _showConfirmApplyJobDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => SpaDialog(
        iconColor: ColorConfig.primary,
        title: 'Xác nhận',
        body: 'Xác nhận Ứng tuyển đơn việc?',
        cancelLabel: 'Đóng',
        confirmLabel: 'Xác nhận',
        confirmColor: ColorConfig.primary,
        onConfirm: () {},
      ),
    );

    if (result == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator(color: ColorConfig.primary)),
      );

      try {
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          SnackBarHelper.showWarning(context, "Chức năng đang được phát triển!!");
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        SnackBarHelper.showError(context, "Ứng tuyển đơn việc: $e");
      }
    }
  }

  void _showFilterBottomSheet() {
    _tempServiceId = _selectedServiceId;
    _tempTimeFilter = _selectedTimeFilter;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Bộ lọc',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Service filter
                  const Text(
                    'Dịch vụ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedServiceId,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Tất cả'),
                          ),
                          ...?allServices?.map((service) => DropdownMenuItem(
                            value: service['_id'],
                            child: Text(service['name'] ?? 'Không tên'),
                          )),
                        ],
                        // onChanged: (value) {
                        //   setStateBottomSheet(() {
                        //     _selectedServiceId = value ?? 'all';
                        //   });
                        //   setState(() {
                        //     _selectedServiceId = value ?? 'all';
                        //     _applyFilter();
                        //   });
                        // },
                        onChanged: (value) {
                          setStateBottomSheet(() {
                            _tempServiceId = value ?? 'all'; // chỉ cập nhật biến tạm
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Time filter
                  // const Text(
                  //   'Thời gian dịch vụ',
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  // ),
                  // const SizedBox(height: 12),
                  // Container(
                  //   height: 50,
                  //   decoration: BoxDecoration(
                  //     border: Border.all(color: Colors.grey.shade300),
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: DropdownButtonHideUnderline(
                  //     child: DropdownButton<String>(
                  //       value: _selectedTimeFilter,
                  //       isExpanded: true,
                  //       padding: const EdgeInsets.symmetric(horizontal: 16),
                  //       items: const [
                  //         DropdownMenuItem(
                  //           value: 'all',
                  //           child: Text('Tất cả'),
                  //         ),
                  //         DropdownMenuItem(
                  //           value: '60',
                  //           child: Text('Dưới 60 phút'),
                  //         ),
                  //         DropdownMenuItem(
                  //           value: '90',
                  //           child: Text('Dưới 90 phút'),
                  //         ),
                  //         DropdownMenuItem(
                  //           value: '120',
                  //           child: Text('Dưới 120 phút'),
                  //         ),
                  //       ],
                  //       // onChanged: (value) {
                  //       //   setStateBottomSheet(() {
                  //       //     _selectedTimeFilter = value ?? 'all';
                  //       //   });
                  //       //   setState(() {
                  //       //     _selectedTimeFilter = value ?? 'all';
                  //       //     _applyFilter();
                  //       //   });
                  //       // },
                  //       onChanged: (value) {
                  //         setStateBottomSheet(() {
                  //           _tempTimeFilter = value ?? 'all'; // chỉ cập nhật biến tạm
                  //         });
                  //       },
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 24),

                  // Reset button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          // onPressed: () {
                          //   setStateBottomSheet(() {
                          //     _selectedServiceId = 'all';
                          //     _selectedTimeFilter = 'all';
                          //   });
                          //   setState(() {
                          //     _selectedServiceId = 'all';
                          //     _selectedTimeFilter = 'all';
                          //     _applyFilter();
                          //   });
                          //   Navigator.pop(context);
                          // },
                          onPressed: () {
                            setStateBottomSheet(() {
                              _tempServiceId = 'all';
                              _tempTimeFilter = 'all';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          // onPressed: () {
                          //   Navigator.pop(context);
                          // },
                          onPressed: () {
                            setState(() {
                              _selectedServiceId = _tempServiceId;
                              _selectedTimeFilter = _tempTimeFilter;
                              _applyFilter(); // chỉ chạy ở đây
                            });
                            Navigator.pop(context);
                            FocusScope.of(context).unfocus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConfig.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Áp dụng',
                            style: TextStyle(
                              color: ColorConfig.textWhite
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.isNegative) return 'Đã hết hạn';
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (days > 0) {
      return '$days ngày ${hours.toString().padLeft(2, '0')}h';
    } else if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}h';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Color _getTimerColor(Duration duration) {
    if (duration.inMinutes < 1) {
      return Colors.red.shade600;
    } else if (duration.inMinutes < 5) {
      return Colors.orange.shade600;
    } else {
      return Colors.green.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _loadBookOrders,
        child: SafeArea(
          child: Column(
            children: [
              // Search and Filter Row
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child:
                        // TextField(
                        //   controller: _searchController,
                        //   decoration: InputDecoration(
                        //     hintText: 'Tìm kiếm theo địa chỉ...',
                        //     hintStyle: TextStyle(color: Colors.grey.shade400),
                        //     // prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                        //     border: InputBorder.none,
                        //     contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        //   ),
                        // ),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm theo địa chỉ...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,

                            // Padding custom
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),

                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 20,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchAddress = '';
                                  _applyFilter();
                                });
                              },
                            )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _searchAddress = _searchController.text;
                            _applyFilter();
                          });
                        },
                        icon: Icon(Icons.search, color: ColorConfig.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: ColorConfig.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _showFilterBottomSheet,
                        icon: const Icon(Icons.filter_list, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBookOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConfig.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedServiceId == 'all' && _searchAddress.isEmpty && _selectedTimeFilter == 'all'
                    ? Icons.inbox_outlined
                    : Icons.search_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedServiceId == 'all' && _searchAddress.isEmpty && _selectedTimeFilter == 'all'
                  ? 'Không có đơn việc nào'
                  : 'Không tìm thấy đơn việc',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedServiceId == 'all' && _searchAddress.isEmpty && _selectedTimeFilter == 'all'
                  ? 'Hãy kiểm tra lại sau'
                  : 'Hãy thử thay đổi bộ lọc tìm kiếm',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredJobs.length,
      itemBuilder: (context, index) {
        final job = filteredJobs[index];
        final orderId = job['_id'];
        final remainingTime = _remainingTimes[orderId] ?? Duration.zero;

        return JobCard(
          isWorking: isWorking,
          job: job,
          remainingTime: remainingTime,
          onAccept: () => _acceptJob(job),
          onTap: () async {
            final result = await context.push(
              '${TechnicianRouterConfig.detailsOrder}/${orderId}',
              extra: true,
            );
            if (result != null && result is Map && result['success'] == true) {
              setState(() {
                listJobs.removeWhere((e) => e['_id'] == orderId);
                _remainingTimes.remove(orderId);
                _applyFilter();
              });
            }
          },
          formatRemainingTime: _formatRemainingTime,
          getTimerColor: _getTimerColor,
        );
      },
    );
  }
}