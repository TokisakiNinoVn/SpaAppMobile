import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/order_provider.dart';
import 'package:spa_app/providers/selected_tab_provider.dart';
import 'package:spa_app/routes/config/technician_router_config.dart';
import 'package:spa_app/screens/customer/tabs/components/SpaDialog.dart';
import 'package:spa_app/screens/technician/tabs/components/accept_order_dialog.dart';
import 'package:spa_app/screens/technician/tabs/components/job_card_get_job.dart';
import 'package:spa_app/screens/widgets/empty_refresh_widget.dart';
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
  List<dynamic> listRequestEntrust = [];

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCheckWorkingOrder();
      loadRequestEntrustOrder();
    });

    _loadAllServices();
    _loadBookOrders();
    _startCountdownTimer();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _realtimeService = RealtimeService.instance;

    // Đăng ký callback sau khi có instance
    _realtimeService.onOrderRemoved = (orderId) {
      if (!mounted) return;
      setState(() {
        listJobs.removeWhere((e) => e['_id'] == orderId);
        _remainingTimes.remove(orderId);
        _applyFilter();
      });
    };

    _realtimeService.onNewOrderAutoMatching = _handleNewOrder;

    // QUAN TRỌNG: gọi init để kết nối WebSocket
    _realtimeService.init(context: context);
  }

  Future<void> loadRequestEntrustOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final bool success = await orderProvider.requestEntrustOrder();

    if (success) {
      setState(() {
        listRequestEntrust = orderProvider.listTechnicianRequestEntrust;
        appLog("Data list request entrust: $listRequestEntrust");
        _applyFilter();
      });

      // appLog("Lấy danh sách đơn việc được giao thành công");
    } else {
      appLog("Lấy danh sách đơn việc được giao thất bại");
    }
  }

  void _handleNewOrder(Map<String, dynamic> payload) {
    // Lấy order thật
    final Map<String, dynamic> actualOrder =
        (payload['data'] is Map<String, dynamic>) ? payload['data'] : payload;

    // appLog("Data new order: $actualOrder");

    // Nếu đang làm việc thì bỏ qua
    if (isWorking) return;

    final String? orderId = actualOrder['_id']?.toString();
    if (orderId == null) return;

    // Tránh duplicate order
    final bool alreadyExists = listJobs.any(
      (o) => o['_id']?.toString() == orderId,
    );

    if (alreadyExists) return;

    // Parse expiresAt
    Duration? initialRemaining;

    try {
      final expiresAtStr = actualOrder['expiresAt'];

      if (expiresAtStr is String && expiresAtStr.isNotEmpty) {
        final expiryTime = DateTime.parse(expiresAtStr);
        final now = DateTime.now();

        // Nếu hết hạn rồi thì bỏ
        if (expiryTime.isBefore(now)) return;

        initialRemaining = expiryTime.difference(now);
      }
    } catch (e) {
      appLog("Parse expiresAt error: $e");
    }

    if (!mounted) return;

    setState(() {
      listJobs.insert(0, actualOrder);

      if (initialRemaining != null && initialRemaining!.inSeconds > 0) {
        _remainingTimes[orderId] = initialRemaining!;
      }
    });

    _startTimerForSingleOrder(actualOrder);
    _applyFilter();
  }

  void _applyFilter() {
    final now = DateTime.now();
    final newFiltered =
        listJobs.where((job) {
          // Filter by service
          if (_selectedServiceId != 'all' &&
              job['serviceId'] != _selectedServiceId) {
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

  Future<void> loadCheckWorkingOrder() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);

    try {
      setState(() {
        _errorMessage = '';
      });

      final success = await provider.checkWorkingOrder();

      if (success) {
        setState(() {
          isWorking = provider.workingOrder["isWorking"] ?? false;
          // appLog("orderDetail: $isWorking"); // true
          // appLog("orderDetail: ${provider.workingOrder}");
        });
      } else {
        setState(() {
          _errorMessage =
              provider.errorMessage ?? 'Không thể lấy thông tin đơn hàng';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      appLog('Error check working order: $e');
    }
  }

  @override
  void dispose() {
    // _realtimeService.dispose();
    // _realtimeService.disconnect();
    _realtimeService.onOrderRemoved = null;
    _realtimeService.onNewOrderAutoMatching = null;

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
    // isWorking = await SharedPrefs.getValue(PrefType.bool, "isWorking") ?? false;

    try {
      final response = await _serviceService.listService();
      setState(() {
        allServices = response['data'];
        // appLog("List service: $allServices");
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

      final queryParams =
          'status=pending&typeOrder=automatic-matching&timeRange=2d';
      final response = await _orderService.listFilterOrder(queryParams);
      // appLog("response : $response");

      if (response['success'] == true) {
        final newOrders = response['data'] ?? [];
        final now = DateTime.now();

        final validOrders =
            newOrders.where((job) {
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
        throw Exception(
          response['message'] ?? 'Không thể tải danh sách đơn đặt trước',
        );
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
    String idOrder = job['_id'];
    if (isAdminCreate) {
      _showConfirmApplyJobDialog(idOrder);
      return;
    } else {
      // SnackBarHelper.showWarning(context, 'Chức năng đang phát triển!');
      showAcceptOrderDialog(
        context: context,
        order: job,
        onConfirm: (message) async {
          await _acceptOrderWithMessage(job, message);
        },
      );
    }
  }

  Future<void> _acceptOrderWithMessage(
    Map<String, dynamic> order,
    String message,
  ) async {
    try {
      final idOrder = order["_id"];
      if (order['subTypeOrder'] == 'now') {
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
          await SharedPrefs.saveValue(
            PrefType.string,
            "idOrderWorking",
            idOrder,
          );
          await SharedPrefs.saveValue(
            PrefType.string,
            "acceptedAt",
            acceptedAt,
          );
          SnackBarHelper.showSuccess(context, "Nhận đơn thành công!");
          // context.go(TechnicianRouterConfig.homeTechnician);
          context.read<SelectedTabProvider>().setIndex(0);
          context.go(TechnicianRouterConfig.homeTechnician);
        }
      } else if (order['subTypeOrder'] == 'book') {
        final data = {'orderId': idOrder, 'result': 'approved'};
        final response = await _orderService.updateStatus(data);
        if (response['success'] == true) {
          if (!mounted) return;
          SnackBarHelper.showSuccess(
            context,
            "Nhận đơn việc đặt trước thành công!",
          );
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

  Future<void> _showConfirmApplyJobDialog(String idOrder) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => SpaDialog(
            iconColor: ColorConfig.primary,
            title: 'Xác nhận ứng tuyển đơn việc',
            body: 'Bạn có chắc chắn muốn ứng tuyển đơn dịch vụ này không?',
            cancelLabel: 'Hủy',
            confirmLabel: 'Ứng tuyển',
            confirmColor: ColorConfig.primary,
            onConfirm: () {
              // Navigator.pop(dialogContext, true);
            },
          ),
    );

    if (result != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Center(
            child: CircularProgressIndicator(color: ColorConfig.primary),
          ),
    );

    try {
      // appLog("Apply order: $idOrder");

      final provider = context.read<OrderProvider>();
      final success = await provider.technicianApplyOrder(idOrder);

      // Đóng loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      if (success) {
        SnackBarHelper.showSuccess(context, "Ứng tuyển đơn việc thành công!");
      } else {
        SnackBarHelper.showError(
          context,
          provider.errorMessage ?? "Ứng tuyển thất bại!",
        );
      }
    } catch (e) {
      // Đóng loading nếu lỗi
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      appLog("Apply order error: $e");

      SnackBarHelper.showError(context, "Ứng tuyển đơn việc thất bại: $e");
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                          ...?allServices?.map(
                            (service) => DropdownMenuItem(
                              value: service['_id'],
                              child: Text(service['name'] ?? 'Không tên'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setStateBottomSheet(() {
                            _tempServiceId = value ?? 'all';
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Reset button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
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
                            style: TextStyle(color: ColorConfig.textWhite),
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

  String _formatRemainingTime(Duration d) {
    if (d.isNegative) return '00:00';
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
      backgroundColor: ColorConfig.primaryBackground,
      body: RefreshIndicator(
        // onRefresh: _loadBookOrders,
        onRefresh: () async {
          await _loadAllServices();
          await _loadBookOrders();
          await loadRequestEntrustOrder();
        },
        backgroundColor: ColorConfig.primaryBackground,
        color: ColorConfig.primary,
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

                            suffixIcon:
                                _searchController.text.isNotEmpty
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
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Entrust Section ──────────────────────────────────────────────────────
  Widget _buildEntrustCard(Map<String, dynamic> entrust) {
    final order = entrust['orderId'] as Map<String, dynamic>? ?? {};
    final orderId = order['_id']?.toString() ?? '';
    final nameService = order['nameService'] ?? 'Dịch vụ';
    final address = order['address'] ?? '';
    final workingHours = order['workingHours'] ?? '';
    final subTypeOrder = order['subTypeOrder'] ?? '';
    final pricing = order['pricing'] as Map<String, dynamic>? ?? {};
    final technicianReceiveAmount = pricing['technicianReceiveAmount'] ?? 0;

    // Tính thời gian còn lại của entrust
    final expiresAtStr = entrust['expiresAt']?.toString();
    Duration? remaining;
    if (expiresAtStr != null) {
      try {
        final expires = DateTime.parse(expiresAtStr).toLocal();
        remaining = expires.difference(DateTime.now());
        if (remaining.isNegative) remaining = Duration.zero;
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () async {
        if (orderId.isEmpty) return;
        await context.push(
          '${TechnicianRouterConfig.detailsOrder}/$orderId',
          extra: {
            'isEntrust': true,
            'isNewOrder': true,
            'orderExpiredAt': entrust['expiresAt'],

          },
        );
        // Reload danh sách sau khi quay lại
        loadRequestEntrustOrder();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorConfig.primary.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConfig.primary.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConfig.primary,
                    ColorConfig.primary.withOpacity(0.75),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Việc được giao',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (remaining != null && remaining > Duration.zero)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatRemainingTime(remaining),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên dịch vụ
                  Text(
                    nameService,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Địa chỉ
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (workingHours.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          workingHours,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Thu nhập + loại đơn
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '${FormatHelper.formatPrice(technicianReceiveAmount)} đ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConfig.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          subTypeOrder == 'now' ? 'Ngay' : 'Hẹn giờ',
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorConfig.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConfig.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: ColorConfig.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrustSection() {
    if (listRequestEntrust.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: ColorConfig.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Các việc được giao',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorConfig.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${listRequestEntrust.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...listRequestEntrust.map(
            (e) => _buildEntrustCard(e as Map<String, dynamic>),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────
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
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
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

    // Khi danh sách jobs trống nhưng có entrust → hiển thị entrust + empty widget
    if (filteredJobs.isEmpty) {
      if (listRequestEntrust.isNotEmpty) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEntrustSection(),
              const SizedBox(height: 8),
              // Section header đơn mới
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Các đơn việc mới',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: EmptyRefreshWidget(
                  onRefresh: _loadBookOrders,
                  title:
                      _selectedServiceId == 'all' &&
                              _searchAddress.isEmpty &&
                              _selectedTimeFilter == 'all'
                          ? 'Hiện tại chưa có đơn việc nào'
                          : 'Không tìm thấy đơn việc',
                  subTitle: "Nơi này khá trống trải...!",
                  icon:
                      _selectedServiceId == 'all' &&
                              _searchAddress.isEmpty &&
                              _selectedTimeFilter == 'all'
                          ? Icons.inbox_outlined
                          : Icons.search_off_rounded,
                  buttonText: 'Tải lại',
                  heightFactor: 1,
                ),
              ),
            ],
          ),
        );
      }

      return EmptyRefreshWidget(
        onRefresh: _loadBookOrders,
        title:
            _selectedServiceId == 'all' &&
                    _searchAddress.isEmpty &&
                    _selectedTimeFilter == 'all'
                ? 'Hiện tại chưa có đơn việc nào'
                : 'Không tìm thấy đơn việc',
        subTitle: "Nơi này khá trống trải...!",
        icon:
            _selectedServiceId == 'all' &&
                    _searchAddress.isEmpty &&
                    _selectedTimeFilter == 'all'
                ? Icons.inbox_outlined
                : Icons.search_off_rounded,
        buttonText: 'Tải lại',
        heightFactor: 0.65,
      );
    }

    // Có cả 2 danh sách → dùng CustomScrollView để ghép
    return CustomScrollView(
      slivers: [
        // Section: Các việc được giao
        if (listRequestEntrust.isNotEmpty)
          SliverToBoxAdapter(child: _buildEntrustSection()),

        // Section header: Các đơn việc mới
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: ColorConfig.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Các đơn việc mới',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConfig.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredJobs.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Danh sách đơn mới
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
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
                    extra: {
                      'isEntrust': false,
                      'isNewOrder': true,
                    },
                  );
                  if (result != null &&
                      result is Map &&
                      result['success'] == true) {
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
            }, childCount: filteredJobs.length),
          ),
        ),
      ],
    );
  }
}
