import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/technician_router_config.dart';
import 'package:spa_app/screens/components/dashed_divider_component.dart';
import 'package:spa_app/services/order_service.dart';

import '../../../helper/check_login_helper.dart';
import '../../../routes/config/customer_router_config.dart';
import '../../../routes/config/global_router_config.dart';

class HistoryOrder extends StatefulWidget {
  const HistoryOrder({super.key});

  @override
  State<HistoryOrder> createState() => _HistoryOrderState();
}

class _HistoryOrderState extends State<HistoryOrder> {
  final OrderService _orderService = OrderService();

  bool _isLoading = true;
  bool _isLogin = false;
  String _errorMessage = '';

  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Đã hoàn thành', 'Đã hủy', 'Hết thời gian chờ', ];
  // final List<String> _filters = ['Tất cả', 'Đang chờ', 'Đang làm', 'Đã hoàn thành', 'Đã hủy', 'Hết thời gian chờ', ];

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
        return _orders.where((order) => order['status'] == 'canceled').toList();
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
          // appLog("List order: $_orders");
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

  void _onOrderExpired(String orderId) {
    setState(() {
      final index = _orders.indexWhere((order) => order['_id'] == orderId);
      if (index != -1 && _orders[index]['status'] == 'pending') {
        _orders[index]['status'] = 'expired';
        SnackBarHelper.showWarning(context, 'Đơn hàng đã hết thời gian chờ');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lịch sử các đơn việc",
          style: TextStyle(
              fontSize: 20,
              color: ColorConfig.textBlack,
              fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: ColorConfig.primaryBackground,
      ),
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
              // _buildHeader(),
              // const SizedBox(height: 10),

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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,

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
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: ColorConfig.primary,
              ),
              child: const Text(
                'Tải lại danh sách',
                style: TextStyle(color: Colors.white),
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
    // appLog("$order");
    final status = order['status'] ?? 'pending';
    final typeOrder = order['typeOrder'] ?? "";
    final price = order['price'] ?? 0;

    final pricing = order['pricing'] ?? {};
    final platformFeeAmount = pricing['platformFeeAmount'] ?? 0;
    final technicianReceiveAmount = pricing['technicianReceiveAmount'] ?? 0;
    final platformFeePercent = pricing['platformFeePercent'] ?? 0;

    final duration = order['serviceTimePrice']?['duration'] ?? 0;

    final customer = order['customerInfor'] ?? {};
    final customerName = customer['fullname'] ?? 'Chưa xác định';
    final customerPhone = customer['phone'] ?? '';
    final customerGender = (customer['gender'] ?? '') == "male" ? "nam" : "nữ";

    final workingHours = order['workingHours'] ?? '';
    final address = order['address'] ?? '';
    final rate = order['rate'];

    final deposit = order['deposit'] ?? 0;
    final isPrioritize = order['isPrioritize'] ?? false;
    final reasonReject = order['reasonReject'] ?? '';

    final submittedAt = order['submittedAt'];
    final approvedAt = order['approvedAt'];
    final rejectedAt = order['rejectedAt'];
    final expiresAt = order['expiresAt'];

    Color statusColor;
    String statusText;
    String typeOderDisplay;

    switch (status) {
      case "pending":
        statusColor = Colors.orange;
        statusText = "Đang chờ";
        break;
      case "approved":
        statusColor = Colors.blue;
        statusText = "Đã nhận";
        break;
      case "done":
        statusColor = Colors.green;
        statusText = "Hoàn thành";
        break;
      case "canceled":
        statusColor = Colors.red;
        statusText = "Đã huỷ";
        break;
      case "expired":
        statusColor = Colors.grey;
        statusText = "Hết hạn";
        break;
      case "rejected":
        statusColor = Colors.orange;
        statusText = "Từ chối";
        break;
      default:
        statusColor = Colors.orange;
        statusText = "${status}";
    }

    switch (typeOrder) {
      case "book":
        typeOderDisplay = "Đặt trước";
        break;
      case "order-now":
        typeOderDisplay = "Đặt ngay";
        break;
      case "automatic-matching":
        typeOderDisplay = "Tự động ghép";
        break;
      default:
        typeOderDisplay = "${typeOrder}";
    }

    // Hàm helper hiển thị thông tin khách hàng theo trạng thái
    Widget _buildCustomerInfo() {
      if (status == 'done') {
        // Hoàn thành: hiện tên, giới tính, sđt
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (customerGender.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Giới tính: $customerGender',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            if (customerPhone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                customerPhone,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ],
        );
      } else if (status == 'expired') {
        // Hết hạn: hiển thị placeholder "Khách nữ"
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khách nữ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              'Thông tin đã hết hạn',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        );
      } else {
        // Các trạng thái khác (pending, approved, cancel): ẩn thông tin chi tiết
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khách hàng',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              'Chưa thể hiển thị',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
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
          context.push('${TechnicianRouterConfig.detailsOrder}/${order['_id']}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (isPrioritize) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      size: 14,
                                      color: Colors.purple,
                                    ),
                                    // SizedBox(width: 1),
                                    Text(
                                      "Ưu tiên",
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // const Icon(
                                    //   Icons.flash_on,
                                    //   size: 14,
                                    //   color: Colors.purple,
                                    // ),
                                    // const SizedBox(width: 4),
                                    Text(
                                      typeOderDisplay,
                                      style: const TextStyle(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorConfig.primaryBackground,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                     Icon(
                                      Icons.monetization_on,
                                      size: 14,
                                      color: ColorConfig.textPrimary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      FormatHelper.formatPrice(price),
                                      style: TextStyle(
                                        color: ColorConfig.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        const DashedDivider(),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order['nameService'] ?? 'Dịch vụ không xác định',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                ),
                                const SizedBox(width: 2),
                                Text("$duration phút"),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const DashedDivider(),

                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              /// TYPE ORDER CHIP
              // Row(
              //   children: [
              //     const SizedBox(width: 8),
              //     _buildChip(
              //       Icons.payments_outlined,
              //       typeOderDisplay,
              //       isPrimary: true,
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 5),
              if (order['submittedAt'] != null) ...[
                // const SizedBox(height: 4),
                Row(
                  children: [
                    // const Icon(Icons.schedule, size: 12, color: Colors.grey),
                    // const SizedBox(width: 4),
                    Text(
                      'Tạo lúc: ${FormatHelper.formatDateTime(order['submittedAt'])}',
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              /// CUSTOMER SECTION (conditional)
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCustomerInfo()),
                ],
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
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
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              /// TIMELINE
              // Column(
              //   children: [
              //     if (submittedAt != null)
              //       _buildTimelineItem(
              //         icon: Icons.schedule,
              //         title: "Tạo đơn",
              //         value: FormatHelper.formatDateTime(submittedAt),
              //       ),
              //     if (approvedAt != null)
              //       _buildTimelineItem(
              //         icon: Icons.check_circle,
              //         title: "Nhận đơn",
              //         value: FormatHelper.formatDateTime(approvedAt),
              //       ),
              //     if (rejectedAt != null)
              //       _buildTimelineItem(
              //         icon: Icons.cancel,
              //         title: "Từ chối",
              //         value: FormatHelper.formatDateTime(rejectedAt),
              //       ),
              //     if (expiresAt != null && status == "expired")
              //       _buildTimelineItem(
              //         icon: Icons.timer_off,
              //         title: "Hết hạn",
              //         value: FormatHelper.formatDateTime(expiresAt),
              //       ),
              //   ],
              // ),
              // if (status == 'pending') ...[
              //   // const SizedBox(height: 10),
              //   _OrderCountdownWidget(
              //     order: order,
              //     onExpired: () => _onOrderExpired(order['_id']),
              //   ),
              // ],
              Divider(color: Colors.grey.withOpacity(0.2)),
              /// ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'pending' || status == 'approved') ...[
                    buildActionButton(
                      onPressed: () {
                        context.push("${TechnicianRouterConfig.canceledOrder}/${order['_id']}");
                      },
                      icon: Icons.close,
                      label: "Huỷ đơn",
                      color: Colors.red,
                    ),
                  ],
                  // if (status == 'done') ...[
                  //   if (rate != null && rate.isNotEmpty) ...[
                  //     buildActionButton(
                  //       onPressed: () {
                  //         final orderId = order["_id"];
                  //         final technicianId = order["technicianInfor"]["_id"];
                  //         final Map<String, dynamic> data = {
                  //           "orderId": orderId,
                  //           "technicianId": technicianId,
                  //           ...rate,
                  //         };
                  //         context.push(CustomerRouterConfig.viewOrUpdateRate, extra: data);
                  //       },
                  //       icon: Icons.arrow_right,
                  //       label: "Xem đánh giá",
                  //       color: Colors.amber.shade700,
                  //     ),
                  //   ],
                  // ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.grey,
          ),

          const SizedBox(width: 8),

          Text(
            "$title:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
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
              color: ColorConfig.primary,
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

class _OrderCountdownWidget extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onExpired;

  const _OrderCountdownWidget({
    required this.order,
    required this.onExpired,
  });

  @override
  State<_OrderCountdownWidget> createState() => _OrderCountdownWidgetState();
}

// class _DashedDivider extends StatelessWidget {
//   const _DashedDivider();
//
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final dashWidth = 6.0;
//         final dashSpace = 4.0;
//         final dashCount =
//         (constraints.maxWidth / (dashWidth + dashSpace)).floor();
//
//         return Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: List.generate(dashCount, (_) {
//             return Container(
//               width: dashWidth,
//               height: .3,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade400,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             );
//           }),
//         );
//       },
//     );
//   }
// }

class _OrderCountdownWidgetState extends State<_OrderCountdownWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
      if (_remaining.isNegative || _remaining.inSeconds <= 0) {
        _timer.cancel();
        widget.onExpired();
      }
    });
  }

  void _updateRemaining() {
    final expiresAtStr = widget.order['expiresAt'] as String?;
    if (expiresAtStr == null) {
      _remaining = Duration.zero;
      return;
    }
    final expiresAt = DateTime.parse(expiresAtStr);
    _remaining = expiresAt.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = _getTotalDuration(); // thời gian chờ tối đa
    final percentage = totalDuration.inSeconds > 0
        ? 1 - (_remaining.inSeconds / totalDuration.inSeconds)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: percentage.clamp(0.0, 1.0),
          backgroundColor: Colors.grey.shade200,
          color: _remaining.inSeconds < 60 ? Colors.red : Colors.orange,
          minHeight: 5,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Duration _getTotalDuration() {
    final submittedAtStr = widget.order['submittedAt'] as String?;
    final expiresAtStr = widget.order['expiresAt'] as String?;
    if (submittedAtStr == null || expiresAtStr == null) return Duration.zero;
    final start = DateTime.parse(submittedAtStr);
    final end = DateTime.parse(expiresAtStr);
    return end.difference(start);
  }
}