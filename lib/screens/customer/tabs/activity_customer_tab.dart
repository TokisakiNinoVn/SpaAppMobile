import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
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
  final OrderService _orderService = OrderService();

  bool _isLoading = true;
  bool _isLogin = false;
  String _errorMessage = '';

  String _selectedFilter = 'Đang làm';
  final List<String> _filters = ['Đang làm', 'Đang chờ', 'Đã hoàn thành', 'Hết thời gian chờ', 'Đã hủy', 'Tất cả'];

  List<dynamic> _orders = [];

  List<dynamic> get _filteredOrders {
    if (_selectedFilter == 'Tất cả') return _orders;

    switch (_selectedFilter) {
      case 'Đang chờ':
        return _orders.where((order) => order['status'] == 'pending').toList();
      case 'Đang làm':
        return _orders.where((order) => order['status'] == 'approved').toList();
      case 'Đã hoàn thành':
        return _orders.where((order) => order['status'] == 'done').toList();
      case 'Đã hủy':
        return _orders.where((order) => order['status'] == 'rejected').toList();
      case 'Hết thời gian chờ':
        return _orders.where((order) => order['status'] == 'expired').toList();
      default:
        return _orders;
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
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();
    if (loggedIn) {
      _isLogin = true;
      _loadOrders();
    } else
      _isLogin = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      body: _isLogin ? _buildLoggedInView() : _buildGuestView(),
    );
  }

  Widget _buildLoggedInView() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),

              if (_isLoading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 20),
              ] else if (_errorMessage.isNotEmpty) ...[
                _buildErrorWidget(),
              ] else ...[
                _buildFilterSection(),
                // const SizedBox(height: 16),

                // _buildQuickStats(),
                // const SizedBox(height: 24),

                _buildOrdersSection(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Đăng nhập Zen Home Spa",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConfig.textBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                context.go(GlobalRouterConfig.loginOTP);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Đăng nhập"),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử hoạt động',
          style: TextStyle(
            fontSize: 20,
            color: ColorConfig.textBlack,
            fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4), // 👈 giảm mạnh
                child: FilterChip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6), // 👈 giảm padding text
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 👈 bỏ vùng tap thừa
                  visualDensity: VisualDensity.compact, // 👈 nén lại tổng thể

                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : ColorConfig.textBlack,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: ColorConfig.white,
                  selectedColor: ColorConfig.primary,
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? ColorConfig.primary
                          : ColorConfig.primary.withOpacity(.2),
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

  Widget _buildOrdersSection() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Bạn chưa có đơn nào',
              style: TextStyle(
                fontSize: 16,
                color: ColorConfig.textBlack.withOpacity(0.6),
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
                color: ColorConfig.textBlack,
              ),
            ),
            TextButton(
              onPressed: _loadOrders,
              child: Text(
                'Làm mới',
                style: TextStyle(
                  color: ColorConfig.primary,
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
    final price = order['price'] ?? 0;
    final duration = order['serviceTimePrice']['duration'] ?? 0;
    final technicianName =
        order['technicianInfor']['fullName'] ?? 'Chưa xác định';
    final technicianAvatar = FormatHelper.formatNetworkImageUrl(
        order['technicianInfor']['avatar']);
    final workingHours = order['workingHours'] ?? '';
    final address = order['address'] ?? '';
    final rate = order['rate'] ?? '';

    Color statusColor;
    String statusText;

    switch (status) {
      case 'done':
        statusColor = Colors.green;
        statusText = 'Hoàn thành';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Đang chờ';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Đã huỷ';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không xác định';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white,
            // ColorConfig.primary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go('${CustomerRouterConfig.detailOrder}/${order['_id']}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order['nameService'] ?? 'Dịch vụ không xác định',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Container(
                  //   padding:
                  //   const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  //   decoration: BoxDecoration(
                  //     color: statusColor.withOpacity(0.1),
                  //     borderRadius: BorderRadius.circular(20),
                  //   ),
                  //   child: Text(
                  //     statusText,
                  //     style: TextStyle(
                  //       color: statusColor,
                  //       fontSize: 12,
                  //       fontWeight: FontWeight.w600,
                  //     ),
                  //   ),
                  // )
                ],
              ),

              const SizedBox(height: 12),

              /// PRICE + DURATION
              Row(
                children: [
                  _buildChip(
                    Icons.access_time,
                    "$duration phút",
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    Icons.payments_outlined,
                    FormatHelper.formatPrice(price),
                    isPrimary: true,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// TECHNICIAN
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: ColorConfig.primary.withOpacity(.15),
                    backgroundImage: NetworkImage(technicianAvatar),
                    onBackgroundImageError: (_, __) {},
                    child: technicianAvatar.isEmpty
                        ? Icon(Icons.person, color: ColorConfig.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FormatHelper.formatNameTechnician(technicianName),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatWorkingHours(workingHours),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
              ],

              Divider(color: Colors.grey.withOpacity(0.2)),

              /// ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'pending' || status == 'approved') ...[
                    buildActionButton(
                      onPressed: () {
                        SnackBarHelper.showWarning(context, "Chức năng đang phát triển");
                      },
                      icon: Icons.close,
                      label: "Huỷ đơn",
                      color: Colors.red,
                    ),
                  ],

                  if (status == 'done') ...[
                    buildActionButton(
                      onPressed: () {
                        SnackBarHelper.showWarning(context, "Chức năng đang phát triển");
                      },
                      icon: Icons.report,
                      label: "Báo cáo",
                      color: Colors.red,
                    ),

                    const SizedBox(width: 6),

                    if (rate != null && rate.isNotEmpty) ...[
                      buildActionButton(
                        onPressed: () {
                          final orderId = order["_id"];
                          final technicianId = order["technicianInfor"]["_id"];
                          final Map<String, dynamic> data = {
                            "orderId": orderId,
                            "technicianId": technicianId,
                            ...rate,
                          };

                          context.push(CustomerRouterConfig.viewOrUpdateRate, extra: data);
                        },
                        icon: Icons.arrow_right,
                        label: "Xem đánh giá",
                        color: Colors.amber.shade700,
                      ),
                    ] else ...[
                      buildActionButton(
                        onPressed: () {
                          final orderId = order["_id"];
                          final technicianId = order["technicianInfor"]["_id"];
                          context.push(CustomerRouterConfig.createRate,
                              extra: { "orderId": orderId, "technicianId": technicianId }
                          );
                        },
                        icon: Icons.star_rounded,
                        label: "Đánh giá",
                        color: Colors.amber.shade700,
                      ),
                    ],
                  ],
                ],
              )


            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    Color? bgColor,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: color.withOpacity(.6), width: 1),
        backgroundColor: bgColor ?? color.withOpacity(.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }


  /// CHIP nhỏ xinh
  Widget _buildChip(IconData icon, String text,
      {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary
            ? ColorConfig.primary.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: isPrimary ? ColorConfig.primary : Colors.grey),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPrimary ? ColorConfig.primary : Colors.black87,
            ),
          )
        ],
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
            color: ColorConfig.primary.withOpacity(0.2),
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
            color: ColorConfig.textError,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorConfig.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: ColorConfig.textBlack.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConfig.primary,
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
}