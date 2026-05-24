import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/order_provider.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/user_discount_service.dart';
import 'package:intl/intl.dart';

class ManagementPostOrder extends StatefulWidget {
  const ManagementPostOrder({
    super.key,
  });

  @override
  State<ManagementPostOrder> createState() => _ManagementPostOrderState();
}

class _ManagementPostOrderState extends State<ManagementPostOrder> {
  bool _isLoading = true;
  List _listPost = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadListPost();
    });
  }

  Future<void> _loadListPost() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<OrderProvider>();
      final success = await provider.loadListPostOrderAdmin();
      if (success && mounted) {
        setState(() => _listPost = provider.listPost);
      }
    } catch (e) {
      appLog('Lỗi load services: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return dateTimeString;
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

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'completed':
        return 'Hoàn thành';
      default:
        return status;
    }
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
            const Text("Các bài đăng"),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                context.push(AdminRouterConfig.createOrderPost);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Tạo mới"),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listPost.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              "Không có bài đăng nào",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _listPost.length,
        itemBuilder: (context, index) {
          final order = _listPost[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    return InkWell(
      onTap: () {
        SnackBarHelper.showWarning(context, "Chức năng đang được phát triển");
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status và Order ID
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(order['status']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(order['status']),
                      style: TextStyle(
                        color: _getStatusColor(order['status']),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (order['isPrioritize'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ưu tiên',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Service Name
              Text(
                order['nameService'] ?? 'Không có tên',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Address
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order['address'] ?? 'Không có địa chỉ',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Customer info
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Yêu cầu: ${order['genderRequirement'] == 'female' ? 'Nữ' : 'Nam'}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    order['phoneCustomer'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Working hours
              // Row(
              //   children: [
              //     const Icon(Icons.access_time, size: 16, color: Colors.grey),
              //     const SizedBox(width: 4),
              //     Text(
              //       'Giờ làm: ${order['workingHours'] ?? ''}',
              //       style: const TextStyle(fontSize: 14, color: Colors.grey),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 8),

              // Price info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giá dịch vụ:'),
                        Text(
                          _formatCurrency(order['price'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (order['moneyPrioritize'] > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Phí ưu tiên:'),
                          Text(
                            _formatCurrency(order['moneyPrioritize']),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng tiền:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatCurrency(order['pricing']?['finalAmount'] ?? order['price'] ?? 0),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    // if ((order['deposit'] ?? 0) > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('KTV ứng tuyển:'),
                          Text(
                            "${order['totalApplicants'] ?? 0}",
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Footer: time created
              // Row(
              //   children: [
              //     const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
              //     const SizedBox(width: 4),
              //     Text(
              //       'Tạo lúc: ${_formatDateTime(order['createdAt'] ?? '')}',
              //       style: const TextStyle(fontSize: 11, color: Colors.grey),
              //     ),
              //     const Spacer(),
              //     TextButton(
              //       onPressed: () {
              //         // TODO: Xem chi tiết order
              //       },
              //       style: TextButton.styleFrom(
              //         foregroundColor: const Color(0xFF1A1A1A),
              //       ),
              //       child: const Text('Xem chi tiết'),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}