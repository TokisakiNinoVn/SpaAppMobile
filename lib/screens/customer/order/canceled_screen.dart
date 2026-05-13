import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/services/order_service.dart';

class CanceledOrderScreen extends StatefulWidget {
  final String? idOrder;
  const CanceledOrderScreen({
    this.idOrder,
    super.key,
  });

  @override
  State<CanceledOrderScreen> createState() => _CanceledOrderScreenState();
}

class _CanceledOrderScreenState extends State<CanceledOrderScreen> {
  final OrderService _orderService = OrderService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otherReasonController = TextEditingController();

  String? _selectedReason;
  bool _isLoading = false;

  // Danh sách lý do có sẵn
  final List<String> _reasonOptions = [
    'Không còn nhu cầu',
    'Thời gian không phù hợp',
    'Tìm được KTV khác',
    'Giá cao',
    'Lý do khác',
  ];

  @override
  void initState() {
    super.initState();
    appLog("idOrder: ${widget.idOrder}");
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  // Lấy lý do cuối cùng (từ option hoặc nhập tay)
  String _getFinalReason() {
    if (_selectedReason == 'Lý do khác') {
      return _otherReasonController.text.trim().isEmpty
          ? 'Lý do khác'
          : _otherReasonController.text.trim();
    }
    return _selectedReason ?? '';
  }

  // Gọi API hủy đơn
  Future<void> _cancelOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final reason = _getFinalReason();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hoặc nhập lý do hủy')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gửi dữ liệu lên server – điều chỉnh theo API thực tế của bạn
      final Map<String, dynamic> requestData = {
        'orderId': widget.idOrder,
        'result': 'canceled',        // hoặc 'cancelled' tùy backend
        'reasonCancellation': reason,
      };
      final response = await _orderService.updateStatus(requestData);

      // Xử lý response thành công (tùy theo cấu trúc response thực tế)
      if (response['success'] == true || response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hủy đơn thành công!')),
          );
          context.pop(true); // Trả về true để thông báo màn hình trước
        }
      } else {
        throw Exception(response['message'] ?? 'Hủy đơn thất bại');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hiển thị dialog xác nhận trước khi hủy
  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn việc này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _cancelOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
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
            const SizedBox(width: 12),
            const Text("Hủy đơn việc"),
          ],
        ),
      ),
      body: Container(
        color: ColorConfig.primaryBackground,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị mã đơn (tùy chọn)
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFFF5F5F5),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Row(
                //     children: [
                //       const Icon(Icons.receipt, size: 20, color: Colors.grey),
                //       const SizedBox(width: 8),
                //       Text(
                //         'Mã đơn: ${widget.idOrder ?? 'Không có'}',
                //         style: const TextStyle(fontSize: 14),
                //       ),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 24),

                const Text(
                  'Chọn lý do hủy:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),

                // Các lý do dạng radio
                ..._reasonOptions.map(
                      (reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                        if (_selectedReason != 'Lý do khác') {
                          _otherReasonController.clear();
                        }
                      });
                    },
                    activeColor: Colors.blue,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

                // Ô nhập lý do khác (chỉ hiện khi chọn "Lý do khác")
                if (_selectedReason == 'Lý do khác')
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 16),
                    child: TextFormField(
                      controller: _otherReasonController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập lý do cụ thể...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (_selectedReason == 'Lý do khác' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Vui lòng nhập lý do hủy';
                        }
                        return null;
                      },
                    ),
                  ),

                const SizedBox(height: 32),

                // Nút hủy đơn
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _showConfirmDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConfig.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Hủy đơn',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}