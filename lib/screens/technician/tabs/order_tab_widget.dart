import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/screens/technician/tabs/components/request_order_card.dart';
import 'package:spa_app/services/order_service.dart';
import 'dart:async';
import 'package:spa_app/services/realtime_service.dart';

import '../../../storage/index.dart';

class OrderTab extends StatefulWidget {
  const OrderTab({super.key});

  @override
  State<OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<OrderTab> {
  final OrderService _orderService = OrderService();
  late RealtimeService _realtimeService;

  int selectedTab = 0;

  bool _isLoading = true;
  bool isWorking = false;
  bool _isLogin = false;
  String _errorMessage = '';

  List<dynamic> listRequestOrders = [];
  List<dynamic> listBookOrders = [];
  List<dynamic> filteredRequestOrders = [];
  List<dynamic> filteredBookOrders = [];

  // Lưu trữ các timer cho mỗi order
  final Map<String, Timer> _timers = {};
  // Lưu thời gian còn lại cho mỗi order
  final Map<String, Duration> _remainingTimes = {};

  @override
  void initState() {
    super.initState();
    _loadData();

    _realtimeService = RealtimeService(
      onNewOrder: _handleNewOrder,
      onOrderExpired: _handleOrderExpired,
    );

    _realtimeService.connect();
  }

  @override
  void dispose() {
    // Hủy tất cả timer khi dispose
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _handleNewOrder(Map<String, dynamic> order) {
    // Nếu đang làm việc thì không xử lý đơn mới
    if (isWorking) return;

    final actualOrder = order['data'] ?? order;
    final orderId = actualOrder['_id'];

    // Kiểm tra xem order đã tồn tại chưa
    final exists = listRequestOrders.any((o) => o['_id'] == orderId);
    if (exists) return;

    // ✅ Khởi tạo remaining time ngay lập tức
    final expiresAt = actualOrder['expiresAt'];
    Duration? initialRemaining;

    if (expiresAt != null && expiresAt is String) {
      final expiryTime = DateTime.parse(expiresAt);
      final now = DateTime.now();
      if (expiryTime.isAfter(now)) {
        initialRemaining = expiryTime.difference(now);
      }
    }

    // Sử dụng microtask để đảm bảo mounted vẫn còn valid
    Future.microtask(() {
      if (mounted) {
        setState(() {
          // Thêm vào đầu danh sách
          listRequestOrders.insert(0, actualOrder);

          // Khởi tạo remaining time nếu có
          if (initialRemaining != null && initialRemaining.inSeconds > 0) {
            _remainingTimes[orderId] = initialRemaining;
          }
        });

        // Start timer cho order mới
        _startTimerForSingleOrder(actualOrder);
        _updateFilteredOrders();
      }
    });
  }

  // Thêm function mới để start timer cho 1 order duy nhất
  void _startTimerForSingleOrder(dynamic order) {
    final expiresAt = order['expiresAt'];
    final orderId = order['_id'];

    if (expiresAt != null && expiresAt is String) {
      final expiryTime = DateTime.parse(expiresAt);
      final now = DateTime.now();

      if (expiryTime.isAfter(now)) {
        final remaining = expiryTime.difference(now);

        // Cập nhật remaining time
        if (mounted) {
          setState(() {
            _remainingTimes[orderId] = remaining;
          });
        }

        // Tạo timer mới
        final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          final currentRemaining = expiryTime.difference(DateTime.now());
          if (currentRemaining.isNegative) {
            timer.cancel();
            _timers.remove(orderId);
            if (selectedTab == 0) {
              _removeExpiredOrder(orderId);
            }
            if (mounted) {
              setState(() {
                _remainingTimes[orderId] = Duration.zero;
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
      } else {
        if (selectedTab == 0) {
          _removeExpiredOrder(orderId);
        }
      }
    }
  }

  void _handleOrderExpired(String orderId) {
    // Nếu đang làm việc thì không xử lý
    if (isWorking) return;

    // ❌ cancel timer
    _timers[orderId]?.cancel();
    _timers.remove(orderId);
    _remainingTimes.remove(orderId);

    Future.microtask(() {
      if (mounted) {
        setState(() {
          listRequestOrders.removeWhere((o) => o['_id'] == orderId);
        });

        _updateFilteredOrders();
      }
    });
  }

  // ⭐ Gộp chung load 1 lần cả 2 loại orders
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Load isWorking trước
      isWorking = await SharedPrefs.getValue(PrefType.bool, "isWorking") ?? false;

      // Gọi song song cả 2 API để tăng performance
      final results = await Future.wait([
        _orderService.listRequestOrder(),
        _orderService.listApprovedBookOrder(),
      ]);


      final requestResponse = results[0];
      final bookResponse = results[1];

      // Xử lý request orders - chỉ load nếu không đang làm việc
      if (!isWorking) {
        if (requestResponse['success'] == true) {
          final newOrders = requestResponse['data'] ?? [];
          setState(() {
            listRequestOrders = newOrders;
            appLog("List request order: $listRequestOrders");
          });
          _startTimersForOrders(newOrders);
        } else {
          throw Exception(requestResponse['message'] ?? 'Không thể tải danh sách đơn hàng');
        }
      } else {
        // Nếu đang làm việc thì clear list request orders
        setState(() {
          listRequestOrders = [];
          filteredRequestOrders = [];
        });
      }

      // Xử lý book orders - luôn load
      if (bookResponse['success'] == true) {
        final newOrders = bookResponse['data'] ?? [];
        setState(() {
          listBookOrders = newOrders;
          filteredBookOrders = List.from(newOrders);
        });
      } else {
        throw Exception(bookResponse['message'] ?? 'Không thể tải danh sách đơn đặt trước');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  void _startTimersForOrders(List<dynamic> orders) {
    // Hủy các timer cũ
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _remainingTimes.clear();

    // Tạo bản sao của orders để tránh concurrent modification
    final ordersCopy = List.from(orders);

    // Tạo timer mới cho mỗi order
    for (var order in ordersCopy) {
      final expiresAt = order['expiresAt'];
      final orderId = order['_id'];

      if (expiresAt != null && expiresAt is String) {
        final expiryTime = DateTime.parse(expiresAt);
        final now = DateTime.now();

        if (expiryTime.isAfter(now)) {
          final remaining = expiryTime.difference(now);
          _remainingTimes[orderId] = remaining;

          // Tạo timer cập nhật mỗi giây
          final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            // THÊM CHECK MOUNTED Ở ĐÂY
            if (!mounted) {
              timer.cancel();
              return;
            }

            final currentRemaining = expiryTime.difference(DateTime.now());
            if (currentRemaining.isNegative) {
              timer.cancel();
              _timers.remove(orderId);
              // Chỉ xóa đối với tab "Yêu cầu đơn mới"
              if (selectedTab == 0 && !isWorking) {
                _removeExpiredOrder(orderId);
              }
              if (mounted) {
                setState(() {
                  _remainingTimes[orderId] = Duration.zero;
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
        } else {
          _remainingTimes[orderId] = Duration.zero;
          // Chỉ xóa đối với tab "Yêu cầu đơn mới"
          if (selectedTab == 0 && !isWorking) {
            _removeExpiredOrder(orderId);
          }
        }
      }
    }

    _updateFilteredOrders();
  }

  void _removeExpiredOrder(String orderId) {
    // Chỉ xóa khỏi danh sách request orders (yêu cầu đơn mới)
    // Không xóa khỏi book orders
    if (mounted) {
      setState(() {
        listRequestOrders.removeWhere((order) => order['_id'] == orderId);
      });
    }

    _updateFilteredOrders();
  }

  void _updateFilteredOrders() {
    // Request orders: lọc bỏ các order đã hết hạn
    // NHƯNG vẫn hiển thị order mới (chưa có remaining time nhưng chưa hết hạn)
    filteredRequestOrders = listRequestOrders.where((order) {
      final orderId = order['_id'];
      final remaining = _remainingTimes[orderId];

      // Nếu chưa có remaining time, kiểm tra expiresAt
      if (remaining == null) {
        final expiresAt = order['expiresAt'];
        if (expiresAt != null && expiresAt is String) {
          final expiryTime = DateTime.parse(expiresAt);
          final now = DateTime.now();
          // Nếu chưa hết hạn thì hiển thị
          return expiryTime.isAfter(now);
        }
        // Nếu không có expiresAt, vẫn hiển thị (để an toàn)
        return true;
      }

      // Có remaining time, kiểm tra còn hạn không
      return !remaining.isNegative && remaining.inSeconds > 0;
    }).toList();

    // Book orders: hiển thị TẤT CẢ (không lọc)
    filteredBookOrders = List.from(listBookOrders);
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00:00';

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'approved':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Từ chối';
      case 'completed':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTypeOrderText(String typeOrder) {
    return typeOrder == 'order-now' ? 'Đặt ngay' : 'Đặt trước';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            const Text(
              'Các đơn việc của bạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabButton("Yêu cầu đơn mới", 0),
                  const SizedBox(width: 12),
                  _buildTabButton("Đơn đặt trước", 1),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List with pull to refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⭐ Tách riêng logic hiển thị nội dung theo từng tab
  Widget _buildContent() {
    if (_isLoading &&
        ((selectedTab == 0 && filteredRequestOrders.isEmpty) ||
            (selectedTab == 1 && filteredBookOrders.isEmpty))) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // ⭐ Tab 0 - Yêu cầu đơn mới
    if (selectedTab == 0) {
      // Nếu đang làm việc, hiển thị text thông báo
      if (isWorking) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 48),
                const SizedBox(height: 16),
                Text(
                  'Bạn đang thực hiện đơn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'không thể nhận thêm việc mới',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      // Nếu không có đơn
      if (filteredRequestOrders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Không có yêu cầu đơn mới',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      // Hiển thị danh sách đơn
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredRequestOrders.length,
        itemBuilder: (context, index) {
          final order = filteredRequestOrders[index];
          return _buildOrderItem(order);
        },
      );
    }

    // ⭐ Tab 1 - Đơn đặt trước (giữ nguyên)
    else {
      if (filteredBookOrders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Không có đơn đặt trước',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredBookOrders.length,
        itemBuilder: (context, index) {
          final order = filteredBookOrders[index];
          return _buildOrderItem(order);
        },
      );
    }
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = selectedTab == index;
    final count = index == 0 ? filteredRequestOrders.length : listBookOrders.length;
    final displayTitle = index == 1 ? '$title ($count)' : title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (selectedTab != index) {
            setState(() {
              selectedTab = index;
            });
            _loadData();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? ColorConfig.primary : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(40),
          ),
          alignment: Alignment.center,
          child: Text(
            displayTitle,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(dynamic order) {
    appLog("Data order: $order");
    final orderId = order['_id'] ?? '';
    final remainingTime = _remainingTimes[orderId];
    final isExpiringSoon = order['isExpiringSoon'] ?? false;
    final status = order['status'] ?? 'pending';
    final typeOrder = order['typeOrder'] ?? 'order-now';
    final isPrioritize = order['isPrioritize'] ?? false;

    final isBookOrderTab = selectedTab == 1;
    return RequestOrderCard(
      order: order,
      remainingTime: _remainingTimes[order['_id']],
      showTimeline: true,
      onApply: () {
        appLog("Ứng tuyển");
        SnackBarHelper.showWarning(context, "Chức năng đang được phát triển");
      },
    );

    return GestureDetector(
      onTap: () {
        context.push('/home-technician/orders/$orderId');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          // Chỉ hiển thị border cho tab request orders
          border: !isBookOrderTab && isExpiringSoon && remainingTime != null && remainingTime.inMinutes <= 5
              ? Border.all(color: Colors.red.shade300, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order['nameService'] ?? 'Dịch vụ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['customerId']?['fullname'] ?? 'Khách hàng',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Type order and price
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeOrder == 'order-now' ? Colors.blue.shade50 : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getTypeOrderText(typeOrder),
                    style: TextStyle(
                      fontSize: 11,
                      color: typeOrder == 'order-now' ? Colors.blue.shade700 : Colors.purple.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isPrioritize)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ưu tiên',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  '${FormatHelper.formatPrice(order['price'] ?? 0)}đ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['address'] ?? 'Địa chỉ',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Working hours if exists
            if (order['workingHours'] != null && order['workingHours'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Giờ làm: ${order['workingHours']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            const Divider(height: 16),

            // Chỉ hiển thị timeline cho tab "Yêu cầu đơn mới"
            if (!isBookOrderTab)
              _buildCountdownTimeline(order, remainingTime),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownTimeline(dynamic order, Duration? remainingTime) {
    final expiresAt = order['expiresAt'];
    if (expiresAt == null) return const SizedBox.shrink();

    final expiryDateTime = DateTime.parse(expiresAt);
    final totalDuration = const Duration(minutes: 5); // Giả sử thời gian hết hạn là 5 phút
    final progress = remainingTime != null && remainingTime.inSeconds > 0
        ? 1 - (remainingTime.inSeconds / totalDuration.inSeconds)
        : 1.0;

    final isExpired = remainingTime == null || remainingTime.isNegative || remainingTime.inSeconds <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isExpired ? Icons.timer_off : Icons.timer,
                  size: 14,
                  color: isExpired ? Colors.red : (remainingTime?.inMinutes ?? 0) <= 1 ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  isExpired ? 'Đã hết hạn' : 'Thời gian còn lại: ${_formatDuration(remainingTime ?? Duration.zero)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired ? Colors.red : ((remainingTime?.inMinutes ?? 0) <= 1 ? Colors.orange : Colors.grey.shade600),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              FormatHelper.formatDateTime(expiresAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isExpired
                  ? Colors.red
                  : (progress > 0.8)
                  ? Colors.orange
                  : Colors.green,
            ),
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}