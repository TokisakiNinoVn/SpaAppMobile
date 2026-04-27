import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/services/realtime_service.dart';
import 'package:spa_app/services/service_service.dart';

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

  List<dynamic> listJobs = [];
  List<dynamic> filteredJobs = [];
  Map<String, Duration> _remainingTimes = {};
  List<String> _expiredOrders = [];
  List<dynamic>? allServices = [];

  // Filter variables
  String _selectedServiceId = 'all';
  int _totalJobs = 0;

  @override
  void initState() {
    super.initState();
    _loadBookOrders();
    _startCountdownTimer();
    _loadAllServices();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startCountdownTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _updateRemainingTimes();
        _removeExpiredOrders();
      }
      return true;
    });
  }

  void _updateRemainingTimes() {
    final now = DateTime.now();
    bool hasChanges = false;

    for (var job in filteredJobs) {
      final orderId = job['_id'];
      final expiresAt = DateTime.parse(job['expiresAt']);
      final remaining = expiresAt.difference(now);

      if (_remainingTimes[orderId] != remaining && remaining.inSeconds >= 0) {
        _remainingTimes[orderId] = remaining;
        hasChanges = true;
      }
    }

    if (hasChanges && mounted) {
      setState(() {});
    }
  }

  void _removeExpiredOrders() {
    final now = DateTime.now();
    final newlyExpired = <String>[];

    for (var job in filteredJobs) {
      final orderId = job['_id'];
      final expiresAt = DateTime.parse(job['expiresAt']);

      if (expiresAt.isBefore(now) && !_expiredOrders.contains(orderId)) {
        newlyExpired.add(orderId);
      }
    }

    if (newlyExpired.isNotEmpty) {
      setState(() {
        _expiredOrders.addAll(newlyExpired);
        filteredJobs.removeWhere((job) => _expiredOrders.contains(job['_id']));
        listJobs.removeWhere((job) => _expiredOrders.contains(job['_id']));
        newlyExpired.forEach((id) {
          _remainingTimes.remove(id);
        });
        _applyFilter(); // Re-apply filter after removing expired orders
      });
    }
  }

  void _calculateRemainingTime(String orderId, String expiresAtStr) {
    final expiresAt = DateTime.parse(expiresAtStr);
    final remaining = expiresAt.difference(DateTime.now());
    _remainingTimes[orderId] = remaining;
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

  Future<void> _loadBookOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final queryParams = 'typeOrder=automatic-matching&timeRange=2d';
      final response = await _orderService.listFilterOrder(queryParams);
      // appLog("data: $response");

      if (response['success'] == true) {
        final newOrders = response['data'] ?? [];

        setState(() {
          listJobs = List.from(newOrders);
          _totalJobs = listJobs.length;
          _isLoading = false;

          for (var job in listJobs) {
            _calculateRemainingTime(job['_id'], job['expiresAt']);
          }

          final now = DateTime.now();
          listJobs.removeWhere((job) {
            final expiresAt = DateTime.parse(job['expiresAt']);
            return expiresAt.isBefore(now);
          });

          _totalJobs = listJobs.length;
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
      print('Error loading book orders: $e');
    }
  }

  void _applyFilter() {
    if (_selectedServiceId == 'all') {
      filteredJobs = List.from(listJobs);
    } else {
      filteredJobs = listJobs.where((job) {
        final serviceId = job['serviceId'];
        return serviceId == _selectedServiceId;
      }).toList();
    }
    setState(() {});
  }

  void _acceptJob(Map<String, dynamic> job) {
    // context.push()
    _showSnackBar('Đã nhận việc thành công!', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
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
              _buildHeader(),
              _buildFilterChips(),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorConfig.primary.withOpacity(0.2),
                      ColorConfig.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.work_outline,
                  size: 24,
                  color: ColorConfig.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Việc làm mới',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Text(
                    //   'Có $_totalJobs đơn việc đang chờ xử lý',
                    //   style: TextStyle(
                    //     fontSize: 13,
                    //     color: Colors.grey.shade600,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    if (allServices == null || allServices!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "Tất cả" chip
          _buildFilterChip(
            label: 'Tất cả',
            value: 'all',
            icon: Icons.apps_rounded,
          ),
          const SizedBox(width: 8),
          // Service chips
          ...allServices!.map((service) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(
              label: service['name'] ?? 'Không tên',
              value: service['_id'],
              icon: Icons.spa,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedServiceId == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedServiceId = selected ? value : 'all';
          _applyFilter();
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: ColorConfig.primary,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
          width: 1,
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
                _selectedServiceId == 'all'
                    ? Icons.inbox_outlined
                    : Icons.search_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedServiceId == 'all'
                  ? 'Không có đơn việc nào'
                  : 'Không tìm thấy đơn việc',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedServiceId == 'all'
                  ? 'Hãy kiểm tra lại sau'
                  : 'Hãy thử chọn dịch vụ khác',
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
          job: job,
          remainingTime: remainingTime,
          onAccept: () => _acceptJob(job),
          formatRemainingTime: _formatRemainingTime,
          getTimerColor: _getTimerColor,
        );
      },
    );
  }
}

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final Duration remainingTime;
  final VoidCallback onAccept;
  final String Function(Duration) formatRemainingTime;
  final Color Function(Duration) getTimerColor;

  const JobCard({
    super.key,
    required this.job,
    required this.remainingTime,
    required this.onAccept,
    required this.formatRemainingTime,
    required this.getTimerColor,
  });

  @override
  Widget build(BuildContext context) {
    final customer = job['customerId'];
    final serviceTimePrice = job['serviceTimePriceId'];
    final isPrioritize = job['isPrioritize'] ?? false;
    final isExpired = remainingTime.isNegative;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Header với gradient nếu ưu tiên
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isPrioritize
                      ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.orange.shade50,
                      Colors.white,
                    ],
                  )
                      : null,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon service
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorConfig.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.spa,
                        size: 24,
                        color: ColorConfig.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['nameService'] ?? 'Dịch vụ Spa',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isPrioritize)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ưu tiên',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getTimerColor(remainingTime).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: getTimerColor(remainingTime),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatRemainingTime(remainingTime),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: getTimerColor(remainingTime),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Nội dung chính
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Địa chỉ
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            job['address']?.split(',').first ?? 'Đang cập nhật',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Thông tin chi tiết
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            Icons.access_time,
                            '${serviceTimePrice?['duration'] ?? 0} phút',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoRow(
                            Icons.calendar_today,
                            _formatDateTime(job['workingHours']),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Giá
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng thanh toán',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                FormatHelper.formatPrice(job['price']),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              if (job['deposit'] != null && job['deposit'] > 0)
                                Text(
                                  'Cọc: ${FormatHelper.formatPrice(job['deposit'])}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Nút nhận việc
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: isExpired ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpired ? Colors.grey.shade300 : ColorConfig.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isExpired ? 'ĐÃ HẾT HẠN' : 'NHẬN VIỆC NGAY',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'Linh hoạt';
    try {
      final parts = dateTimeStr.split(' ');
      if (parts.length >= 2) {
        final time = parts[1].substring(0, 5);
        return '$time ${parts[0]}';
      }
      return dateTimeStr;
    } catch (e) {
      return dateTimeStr;
    }
  }
}