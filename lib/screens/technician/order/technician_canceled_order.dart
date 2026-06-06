import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/order_service.dart';

class TechnicianCanceledOrder extends StatefulWidget {
  final String idOrder;
  const TechnicianCanceledOrder({
    required this.idOrder,
    super.key,
  });

  @override
  State<TechnicianCanceledOrder> createState() => _TechnicianCanceledOrderState();
}

class _TechnicianCanceledOrderState extends State<TechnicianCanceledOrder> {
  final OrderService _orderService = OrderService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otherReasonController = TextEditingController();

  String? _selectedReason;
  bool _isLoading = false;

  // Danh sách lý do có sẵn
  final List<String> _reasonOptions = [
    'Khách đặt sai thời gian',
    'Khách không phản hồi',
    'Khách yêu cầu hủy',
    'Thời gian không phù hợp',
    'Khu vực quá xa',
    'Không đủ thời gian di chuyển',
    'Đã kín lịch',
    'Sức khỏe không đảm bảo',
    'Không phù hợp dịch vụ yêu cầu',
    'Giá chưa phù hợp',
    'Khách thay đổi địa điểm nhiều lần',
    'Không thể liên hệ khách',
    'Đơn có dấu hiệu không nghiêm túc',
    'Lý do khác',
  ];

  @override
  void initState() {
    super.initState();
    // appLog("idOrder: ${widget.idOrder}");
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
        'result': 'canceled',
        'reasonCancellation': reason,
      };
      final response = await _orderService.updateStatus(requestData);

      // Xử lý response thành công (tùy theo cấu trúc response thực tế)
      if (response['success'] == true || response['status'] == 'success') {
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Hủy đơn thành công!');
          context.pop(true);
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
        title: const Text('Hủy đơn việc'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đơn việc này không?\n\n'
              'Sau khi hủy, đơn việc sẽ không còn được xử lý và thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tiếp tục xem'),
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
            child: const Text('Hủy đơn việc'),
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
            Text(
              "Hủy đơn việc",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: ColorConfig.textBlack,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: ColorConfig.primaryBackground,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: TextFormField(
                        controller: _otherReasonController,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
        
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
        
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).unfocus();
                        },
        
                        decoration: InputDecoration(
                          hintText: 'Nhập lý do cụ thể...',
                          filled: true,
                          fillColor: Colors.grey.shade50,
        
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
        
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
        
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: ColorConfig.primary,
                              width: 1.4,
                            ),
                          ),
        
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
        
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
      ),
    );
  }
}