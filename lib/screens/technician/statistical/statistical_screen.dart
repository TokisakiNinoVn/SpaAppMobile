import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/screens/widgets/date_of_birth_picker_bottom_sheet.dart';
import 'package:spa_app/services/user_service.dart';

class StatisticalTechnicianScreen extends StatefulWidget {
  const StatisticalTechnicianScreen({
    super.key,
  });

  @override
  State<StatisticalTechnicianScreen> createState() => _StatisticalTechnicianScreenState();
}

class _StatisticalTechnicianScreenState extends State<StatisticalTechnicianScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  Map<String, dynamic>? _statisticalData;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStatisticalTechnician();
  }

  Future<void> _loadStatisticalTechnician() async {
    setState(() {
      _isLoading = true;
    });

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String query = "date=$formattedDate";

    try {
      final response = await _userService.getStatisticalTechnicianService(query);
      // appLog("Statistical response: $response");

      if (response['success'] == true) {
        setState(() {
          _statisticalData = response['data'];
        });
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, response['message'] ?? "Lỗi tải thông tin thống kê");
        }
      }
    } catch (e) {
      appLog('Error fetching _loadStatisticalTechnician: $e');
      if (mounted) {
        SnackBarHelper.showError(context, "Lỗi tải thông tin thống kê");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateWithBottomSheet() async {
    final picked = await showDateOfBirthPickerBottomSheet(
      context: context,
      initialDate: _selectedDate,
      minimumDate: DateTime(2020),
      maximumDate: DateTime.now(),
      title: "Chọn ngày thống kê",
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadStatisticalTechnician();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateChip() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final label = isToday
        ? 'Hôm nay'
        : DateFormat('dd/MM/yyyy').format(_selectedDate);

    return GestureDetector(
      onTap: _pickDateWithBottomSheet,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isToday ? ColorConfig.primary.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isToday ? ColorConfig.primary.withOpacity(0.5) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: isToday ? ColorConfig.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isToday ? ColorConfig.primary : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: isToday ? ColorConfig.primary : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        border: Border.all(
          color: color.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.18),
                      color.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const Spacer(),

              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 8),

          /// Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              height: 1,
            ),
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderStatusRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
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
            const SizedBox(width: 12),
            const Text(
              "Thống kê KTV",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
        ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorConfig.primary),
        ),
      )
          : _statisticalData == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "Không có dữ liệu thống kê",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Vui lòng chọn ngày khác",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với tên KTV và filter
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statisticalData!['technicianName'] ?? 'KTV',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            // const SizedBox(height: 4),
                            // Text(
                            //   "Mã KTV: ${_statisticalData!['technicianId']?.toString().substring(0, 8) ?? 'N/A'}...",
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     color: Colors.grey.shade500,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      _buildDateChip(),
                    ],
                  ),
                ],
              ),
            ),

            // 3 thẻ thống kê chính
            // Padding(
            //   padding: const EdgeInsets.all(16),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: _buildStatCard(
            //           title: "Tổng đơn hàng",
            //           value: "${_statisticalData!['totalOrders'] ?? 0}",
            //           icon: Icons.shopping_bag_rounded,
            //           color: ColorConfig.primary,
            //         ),
            //       ),
            //       const SizedBox(width: 14),
            //       Expanded(
            //         child: _buildStatCard(
            //           title: "Đơn hoàn thành",
            //           value: "${_statisticalData!['totalOrdersDone'] ?? 0}",
            //           icon: Icons.verified_rounded,
            //           color: Colors.green,
            //           subtitle:
            //           "Tỉ lệ ${_statisticalData!['completionRate']?.toStringAsFixed(1) ?? 0}%",
            //         ),
            //       ),
            //       const SizedBox(width: 14),
            //       Expanded(
            //         child: _buildStatCard(
            //           title: "Doanh thu",
            //           value: _formatCurrency(
            //             _statisticalData!['totalRevenue'] ?? 0,
            //           ),
            //           icon: Icons.payments_rounded,
            //           color: Colors.orange,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// Revenue Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorConfig.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tổng doanh thu",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                _formatCurrency(
                                  _statisticalData!['totalRevenue'] ?? 0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Bottom Stats
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 18,
                                    color: ColorConfig.primary,
                                  ),

                                  const SizedBox(width: 6),

                                  Expanded(
                                    child: Text(
                                      "Tổng đơn",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "${_statisticalData!['totalOrders'] ?? 0}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                    color: Colors.green,
                                  ),

                                  const SizedBox(width: 6),

                                  Expanded(
                                    child: Text(
                                      "Hoàn thành",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "${_statisticalData!['totalOrdersDone'] ?? 0}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "${_statisticalData!['completionRate']?.toStringAsFixed(1) ?? 0}% hoàn thành",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Thống kê đơn hàng theo trạng thái
            // Container(
            //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(16),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.grey.shade100,
            //         blurRadius: 10,
            //         offset: const Offset(0, 2),
            //       ),
            //     ],
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text(
            //         "Trạng thái đơn hàng",
            //         style: TextStyle(
            //           fontSize: 16,
            //           fontWeight: FontWeight.bold,
            //           color: Color(0xFF1A1A1A),
            //         ),
            //       ),
            //       const SizedBox(height: 16),
            //       _buildOrderStatusRow(
            //         "Đã hủy",
            //         _statisticalData!['totalOrdersCanceled'] ?? 0,
            //         Colors.red,
            //       ),
            //       const SizedBox(height: 12),
            //       _buildOrderStatusRow(
            //         "Đã từ chối",
            //         _statisticalData!['totalOrdersRejected'] ?? 0,
            //         Colors.orange,
            //       ),
            //       const SizedBox(height: 12),
            //       _buildOrderStatusRow(
            //         "Đang chờ",
            //         _statisticalData!['totalOrdersPending'] ?? 0,
            //         Colors.blue,
            //       ),
            //       const SizedBox(height: 12),
            //       _buildOrderStatusRow(
            //         "Đang thực hiện",
            //         _statisticalData!['totalOrdersWorking'] ?? 0,
            //         Colors.purple,
            //       ),
            //     ],
            //   ),
            // ),

            // Thông tin tài chính
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Thông tin tài chính",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    "Tổng giá trị dịch vụ",
                    _formatCurrency(_statisticalData!['totalServiceAmount'] ?? 0),
                  ),
                  _buildInfoRow(
                    "Tổng giảm giá",
                    _formatCurrency(_statisticalData!['totalDiscountAmount'] ?? 0),
                  ),
                  _buildInfoRow(
                    "Phí nền tảng",
                    _formatCurrency(_statisticalData!['totalPlatformFee'] ?? 0),
                  ),
                  _buildInfoRow(
                    "Doanh thu trung bình/đơn",
                    _formatCurrency(_statisticalData!['averageRevenuePerOrder'] ?? 0),
                  ),
                  // _buildInfoRow(
                  //   "Tổng tiền cọc",
                  //   _formatCurrency(_statisticalData!['totalDeposit'] ?? 0),
                  // ),
                ],
              ),
            ),

            // Thông tin đơn hàng đặc biệt
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Loại đơn việc",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    "Đơn ưu tiên",
                    "${_statisticalData!['totalPrioritizeOrders'] ?? 0} đơn",
                  ),
                  if ((_statisticalData!['totalMoneyPrioritize'] ?? 0) > 0)
                    _buildInfoRow(
                      "Tiền ưu tiên",
                      _formatCurrency(_statisticalData!['totalMoneyPrioritize'] ?? 0),
                    ),
                  _buildInfoRow(
                    "Đơn đặt lịch",
                    "${_statisticalData!['bookOrders'] ?? 0} đơn",
                  ),
                  _buildInfoRow(
                    "Đơn tự động ghép",
                    "${_statisticalData!['automaticMatchingOrders'] ?? 0} đơn",
                  ),
                  _buildInfoRow(
                    "Đơn ngay",
                    "${_statisticalData!['orderNowOrders'] ?? 0} đơn",
                  ),
                ],
              ),
            ),

            // Thời gian làm việc
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Thời gian",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    "Thời gian làm việc TB",
                    _statisticalData!['avgWorkingTime'] == 0
                        ? "Chưa có dữ liệu"
                        : "${(_statisticalData!['avgWorkingTime'] / 60).toStringAsFixed(0)} phút",
                  ),
                  if (_statisticalData!['firstOrderDate'] != null)
                    _buildInfoRow(
                      "Đơn đầu tiên",
                      DateFormat('dd/MM/yyyy HH:mm').format(
                        DateTime.parse(_statisticalData!['firstOrderDate']),
                      ),
                    ),
                  if (_statisticalData!['lastOrderDate'] != null)
                    _buildInfoRow(
                      "Đơn gần nhất",
                      DateFormat('dd/MM/yyyy HH:mm').format(
                        DateTime.parse(_statisticalData!['lastOrderDate']),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}