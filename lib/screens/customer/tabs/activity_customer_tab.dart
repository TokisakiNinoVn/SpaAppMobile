import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spa_app/services/order_service.dart';

import '../../../helper/check_login_helper.dart';
import '../../../routes/config/customer_router_config.dart';
import '../../../routes/config/global_router_config.dart';

class ActivityCustomerTab extends StatefulWidget {
  const ActivityCustomerTab({super.key});

  @override
  State<ActivityCustomerTab> createState() => _ActivityCustomerTabState();
}

class _ActivityCustomerTabState extends State<ActivityCustomerTab> {
  // Màu sắc chủ đề Spa
  final Color _spaPrimaryColor = const Color(0xFFD4A574);
  final Color _spaSecondaryColor = const Color(0xFFB08D57);
  final Color _spaBackgroundColor = const Color(0xFFF9F5F0);
  final Color _spaTextColor = const Color(0xFF5D4037);
  final Color _spaLightColor = const Color(0xFFE8D8C3);
  final Color _spaSuccessColor = const Color(0xFF8BC34A);
  final Color _spaWarningColor = const Color(0xFFFF9800);
  final Color _spaCancelColor = const Color(0xFFF44336);
  final Color _spaPendingColor = const Color(0xFF2196F3);

  final OrderService _orderService = OrderService();

  bool _isLoading = true;
  String _errorMessage = '';

  // Biến lọc
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Đang chờ', 'Đã xác nhận', 'Đã hoàn thành', 'Đã hủy'];

  // Dữ liệu đơn hàng từ API
  List<dynamic> _orders = [];

  // Lấy danh sách đã lọc
  List<dynamic> get _filteredOrders {
    if (_selectedFilter == 'Tất cả') return _orders;

    switch (_selectedFilter) {
      case 'Đang chờ':
        return _orders.where((order) => order['status'] == 'pending').toList();
      case 'Đã xác nhận':
        return _orders.where((order) => order['status'] == 'approved').toList();
      case 'Đã hoàn thành':
        return _orders.where((order) => order['status'] == 'completed').toList();
      case 'Đã hủy':
        return _orders.where((order) => order['status'] == 'rejected').toList();
      default:
        return _orders;
    }
  }

  // Map trạng thái API sang tiếng Việt
  Map<String, String> _statusMap = {
    'pending': 'Đang chờ',
    'approved': 'Đã xác nhận',
    'completed': 'Đã hoàn thành',
    'rejected': 'Đã hủy',
  };

  // Map trạng thái API sang màu
  Map<String, Color> _statusColorMap = {
    'pending': const Color(0xFF2196F3),
    'approved': const Color(0xFFFF9800),
    'completed': const Color(0xFF8BC34A),
    'rejected': const Color(0xFFF44336),
  };

  // Format tiền VND
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();
    if (loggedIn)
      _loadOrders();
    else
    context.go(GlobalRouterConfig.signup);
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _orderService.listOrder();

      if (response['success'] == true) {
        setState(() {
          _orders = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải danh sách đơn hàng');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading orders: $e');
    }
  }

  // Format ngày giờ
  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  // Format ngày làm việc
  String _formatWorkingHours(String dateString) {
    try {
      // Chuyển từ định dạng "08/01/2026 18:30" sang định dạng đẹp hơn
      final parts = dateString.split(' ');
      if (parts.length == 2) {
        final datePart = parts[0];
        final timePart = parts[1];
        return '$datePart • $timePart';
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _spaBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với thông tin người dùng
                // _buildHeader(),
                // const SizedBox(height: 24),

                if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 20),
                ] else if (_errorMessage.isNotEmpty) ...[
                  _buildErrorWidget(),
                ] else ...[
                  // Phần lọc
                  _buildFilterSection(),
                  const SizedBox(height: 24),

                  // Thống kê nhanh
                  _buildQuickStats(),
                  const SizedBox(height: 24),

                  // Danh sách đơn hàng
                  _buildOrdersSection(),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildHeader() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Xin chào,',
  //         style: TextStyle(
  //           fontSize: 14,
  //           color: _spaTextColor.withOpacity(0.7),
  //         ),
  //       ),
  //       Text(
  //         'Nguyễn Văn Khách',
  //         style: TextStyle(
  //           fontSize: 24,
  //           fontWeight: FontWeight.bold,
  //           color: _spaTextColor,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Text(
  //         'Theo dõi lịch sử và hoạt động đặt lịch của bạn',
  //         style: TextStyle(
  //           fontSize: 14,
  //           color: _spaTextColor.withOpacity(0.6),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   'Lọc theo trạng thái',
        //   style: TextStyle(
        //     fontSize: 16,
        //     fontWeight: FontWeight.w600,
        //     color: _spaTextColor,
        //   ),
        // ),
        // const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _spaTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: _spaLightColor,
                  selectedColor: _spaPrimaryColor,
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? _spaPrimaryColor : _spaLightColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final totalOrders = _orders.length;
    final completedOrders = _orders.where((order) => order['status'] == 'approved').length;
    final upcomingOrders = _orders.where((order) => order['status'] == 'pending').length;
    final rejectedOrders = _orders.where((order) => order['status'] == 'rejected').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _spaLightColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Tổng đơn', '$totalOrders', Icons.calendar_today),
          _buildStatItem('Đã xác nhận', '$completedOrders', Icons.check_circle),
          _buildStatItem('Đang chờ', '$upcomingOrders', Icons.schedule),
          _buildStatItem('Đã hủy', '$rejectedOrders', Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _spaLightColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _spaPrimaryColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _spaTextColor,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: _spaTextColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersSection() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: _spaLightColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đơn hàng nào',
              style: TextStyle(
                fontSize: 16,
                color: _spaTextColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lịch sử đặt lịch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _spaTextColor,
              ),
            ),
            TextButton(
              onPressed: _loadOrders,
              child: Text(
                'Làm mới',
                style: TextStyle(
                  color: _spaPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._filteredOrders.map((order) => _buildOrderItem(order)),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final statusText = _statusMap[status] ?? 'Không xác định';
    final statusColor = _statusColorMap[status] ?? _spaPendingColor;
    final price = order['price'] ?? 0;
    final technicianName = order['technicianName'] ?? 'Chưa xác định';
    final workingHours = order['workingHours'] ?? '';
    final note = order['noteCustomer'] ?? '';
    final address = order['address'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _spaLightColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // _showOrderDetails(order);
            context.go('${CustomerRouterConfig.detailOrder}/${order['_id']}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với tên dịch vụ và trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order['nameService'] ?? 'Dịch vụ không xác định',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _spaTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Thông tin kỹ thuật viên và thời gian
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _spaLightColor,
                      child: Icon(
                        Icons.person,
                        color: _spaPrimaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kỹ thuật viên: $technicianName',
                            style: TextStyle(
                              fontSize: 14,
                              color: _spaTextColor.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatWorkingHours(workingHours),
                            style: TextStyle(
                              fontSize: 13,
                              color: _spaTextColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Thông tin giá và địa chỉ
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: _spaTextColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 13,
                          color: _spaTextColor.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _currencyFormat.format(price),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _spaPrimaryColor,
                      ),
                    ),
                  ],
                ),

                // Hiển thị ghi chú nếu có
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ghi chú: $note',
                    style: TextStyle(
                      fontSize: 13,
                      color: _spaTextColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Hiển thị thời gian tạo đơn
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: _spaLightColor.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã tạo: ${_formatDateTime(order['createdAt'] ?? '')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _spaTextColor.withOpacity(0.5),
                      ),
                    ),
                    if (status == 'approved' && order['approvedAt'] != null)
                      Text(
                        'Xác nhận: ${_formatDateTime(order['approvedAt'] ?? '')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _spaSuccessColor.withOpacity(0.8),
                        ),
                      ),
                    if (status == 'rejected' && order['rejectedAt'] != null)
                      Text(
                        'Hủy: ${_formatDateTime(order['rejectedAt'] ?? '')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _spaCancelColor.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _spaLightColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: _spaCancelColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _spaTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _spaTextColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: _spaPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final statusText = _statusMap[status] ?? 'Không xác định';
    final statusColor = _statusColorMap[status] ?? _spaPendingColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _spaLightColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiết đơn hàng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _spaTextColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildDetailItem('Dịch vụ:', order['nameService'] ?? 'Không xác định'),
                        _buildDetailItem('Kỹ thuật viên:', order['technicianName'] ?? 'Chưa xác định'),
                        _buildDetailItem('Thời gian làm việc:', order['workingHours'] ?? ''),
                        _buildDetailItem('Địa chỉ:', order['address'] ?? ''),
                        _buildDetailItem('Giá:', '${_currencyFormat.format(order['price'] ?? 0)}'),

                        if (order['noteCustomer']?.isNotEmpty == true)
                          _buildDetailItem('Ghi chú:', order['noteCustomer'] ?? ''),

                        if (order['noteTechnician']?.isNotEmpty == true)
                          _buildDetailItem('Ghi chú kỹ thuật viên:', order['noteTechnician'] ?? ''),

                        _buildDetailItem('Phương thức thanh toán:', order['paymentMethod'] == 'momo' ? 'Momo' : 'Không xác định'),

                        if (order['coupon']?.isNotEmpty == true)
                          _buildDetailItem('Mã giảm giá:', order['coupon'] ?? ''),

                        _buildDetailItem('Thời gian tạo:', _formatDateTime(order['createdAt'] ?? '')),

                        if (order['submittedAt'] != null)
                          _buildDetailItem('Thời gian gửi:', _formatDateTime(order['submittedAt'] ?? '')),

                        if (order['approvedAt'] != null)
                          _buildDetailItem('Thời gian xác nhận:', _formatDateTime(order['approvedAt'] ?? '')),

                        if (order['rejectedAt'] != null)
                          _buildDetailItem('Thời gian hủy:', _formatDateTime(order['rejectedAt'] ?? '')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _spaPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đóng'),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: _spaTextColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: _spaTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: _spaLightColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}