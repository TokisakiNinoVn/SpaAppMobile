import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/services/discount_service.dart';

/// Kết quả trả về sau khi chọn/áp dụng mã giảm giá
class DiscountResult {
  final String code;
  final Map<String, dynamic> data;

  const DiscountResult({required this.code, required this.data});
}

Future<DiscountResult?> showDiscountBottomSheet({
  required BuildContext context,

  /// Giá trị đơn hàng hiện tại (dùng để kiểm tra điều kiện giảm giá)
  required int orderValue,

  /// Danh sách mã giảm giá công khai đã load sẵn
  required List<dynamic> discounts,

  /// Mã đang được áp dụng (nếu có, điền sẵn vào ô nhập)
  String? appliedCode,
}) {
  return showModalBottomSheet<DiscountResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _DiscountBottomSheet(
      orderValue: orderValue,
      discounts: discounts,
      appliedCode: appliedCode,
    ),
  );
}

class _DiscountBottomSheet extends StatefulWidget {
  final int orderValue;
  final List<dynamic> discounts;
  final String? appliedCode;

  const _DiscountBottomSheet({
    required this.orderValue,
    required this.discounts,
    this.appliedCode,
  });

  @override
  State<_DiscountBottomSheet> createState() => _DiscountBottomSheetState();
}

class _DiscountBottomSheetState extends State<_DiscountBottomSheet> {
  final DiscountService _discountService = DiscountService();
  late final TextEditingController _couponController;

  String? _localError;
  bool _localChecking = false;
  String? _selectedDiscountId;

  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _couponController = TextEditingController(text: widget.appliedCode ?? '');
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _localError = 'Vui lòng nhập mã');
      return;
    }

    setState(() {
      _localChecking = true;
      _localError = null;
    });

    try {
      final response = await _discountService.checkDiscountService({
        "code": code,
        "orderValue": widget.orderValue,
      });

      if (response['success'] == true) {
        if (mounted) {
          Navigator.pop(
            context,
            DiscountResult(code: code, data: response['data']),
          );
        }
      } else {
        setState(() {
          _localError = response['message'] ?? 'Mã không hợp lệ';
          _localChecking = false;
        });
      }
    } catch (e) {
      appLog("Lỗi kiểm tra mã: ", data: e);
      setState(() {
        _localError = 'Không thể kiểm tra mã';
        _localChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.7;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn mã giảm giá',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorConfig.textBlack,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey.shade500),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Ô nhập mã + nút áp dụng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Nhập mã khuyến mãi',
                      prefixIcon: const Icon(
                        Icons.discount_outlined,
                        color: _primaryGreen,
                        size: 20,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                        const BorderSide(color: _primaryGreen, width: 1.5),
                      ),
                      errorText: _localError,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    onChanged: (_) {
                      if (_localError != null) {
                        setState(() => _localError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _localChecking ? null : _applyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConfig.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _localChecking
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                    'Áp dụng',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Danh sách mã giảm giá
          Expanded(
            child: widget.discounts.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Không có mã giảm giá nào',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: widget.discounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                const double borderAll = 7;
                final Map<String, dynamic> item =
                widget.discounts[index] as Map<String, dynamic>;

                final String id = item['_id']?.toString() ?? "";
                final String code = item['code']?.toString() ?? "";
                final String typeDiscount =
                    item['typeDiscount']?.toString() ?? "";
                final int value =
                    int.tryParse(item['value'].toString()) ?? 0;
                final int minOrderValue =
                    int.tryParse(item['minOrderValue'].toString()) ?? 0;
                final String expiresAt =
                    item['expiresAt']?.toString() ?? "";
                final bool isSelected = _selectedDiscountId == id;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? _lightGreen : Colors.white,
                    borderRadius: BorderRadius.circular(borderAll),
                    border: Border.all(
                      color: isSelected
                          ? _primaryGreen
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(borderAll),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(borderAll),
                      onTap: () {
                        setState(() {
                          _selectedDiscountId = id;
                          _couponController.text = code;
                        });
                      },
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Cột giảm giá bên trái
                            Container(
                              width: 90,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorConfig.primary
                                    : ColorConfig.primary
                                    .withOpacity(.8),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(borderAll),
                                  topLeft: Radius.circular(borderAll),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Giảm",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      typeDiscount == "percentage"
                                          ? "$value%"
                                          : "${FormatHelper.formatPrice(value)} đ",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Thông tin chi tiết bên phải
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            code,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            size: 20,
                                            color: _primaryGreen,
                                          ),
                                        const SizedBox(width: 10),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Đơn tối thiểu: ${FormatHelper.formatPrice(minOrderValue)}đ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ColorConfig.textBlack
                                            .withOpacity(.8),
                                      ),
                                    ),
                                    Text(
                                      "HSD: ${FormatHelper.formatDateTime(expiresAt)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ColorConfig.textBlack
                                            .withOpacity(.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Nút đóng
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                final hasSelected = _selectedDiscountId != null;
                if (hasSelected) {
                  if (!_localChecking) _applyCode();
                } else {
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: ColorConfig.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ).copyWith(
                overlayColor: WidgetStatePropertyAll(
                  Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if(_selectedDiscountId != null)...[
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ] else
                    Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),

                  const SizedBox(width: 8),
                  Text(
                    _selectedDiscountId != null ? "Áp dụng" : "Đóng",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}