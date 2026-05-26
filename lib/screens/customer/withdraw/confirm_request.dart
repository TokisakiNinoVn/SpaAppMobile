import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/providers/withdraw_provider.dart';
import 'package:spa_app/services/withdraw_service.dart';
import 'package:intl/intl.dart';

class ConfirmRequestWithdraw extends StatefulWidget {
  final Map<String, dynamic> data;

  const ConfirmRequestWithdraw({
    super.key,
    required this.data,
  });

  @override
  State<ConfirmRequestWithdraw> createState() => _ConfirmRequestWithdrawState();
}

class _ConfirmRequestWithdrawState extends State<ConfirmRequestWithdraw> {
  final WithdrawService _withdrawService = WithdrawService();
  bool _isLoading = false;
  String? _errorMessage;

  bool _hasFirstWithdrawalToday = false;
  dynamic _feePercentWithdraw;
  double _feeAmount = 0.0;
  double _netAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _validateData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHasFirstWithdrawToday();
    });
  }

  Future<void> _loadHasFirstWithdrawToday() async {
    final provider = context.read<WithdrawProvider>();
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await provider.checkHasFirstWithdrawalToday();
      setState(() {
        _hasFirstWithdrawalToday = provider.hasFirstWithdrawalToday;
        _feePercentWithdraw = provider.feePercentWithdraw ?? 0;
        appLog("Load: $_hasFirstWithdrawalToday - $_feePercentWithdraw %");
        _calculateFeeAndNet();   // <-- Gọi tính toán
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error get now balance: $e');
    }
  }

  void _calculateFeeAndNet() {
    final double amount = double.tryParse(widget.data['amount'].toString()) ?? 0;
    if (_hasFirstWithdrawalToday) {
      _feeAmount = 0;
    } else {
      _feeAmount = amount * (_feePercentWithdraw / 100);
    }
    _netAmount = amount - _feeAmount;
  }

  void _validateData() {
    if (widget.data == null) {
      _errorMessage = "Không có dữ liệu yêu cầu rút tiền";
    } else if (widget.data!['amount'] == null ||
        widget.data!['bankName'] == null ||
        widget.data!['accountNumber'] == null ||
        widget.data!['accountHolder'] == null) {
      _errorMessage = "Dữ liệu không đầy đủ";
    }
  }

  Future<void> _handleConfirmWithdraw() async {
    // if (_errorMessage != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestData = {
        'amount': int.parse(widget.data['amount'].toString()),
        'bankName': widget.data['bankName'],
        'accountNumber': widget.data['accountNumber']?.toString(),
        'accountHolder': widget.data['accountHolder'],
        'hasFirstWithdrawalToday': _hasFirstWithdrawalToday,
        'fee': _feeAmount,           // thêm nếu cần
        'netAmount': _netAmount,     // thêm nếu cần
      };

      final response = await _withdrawService.createRequest(requestData);
      appLog("$response");
      if (mounted) {
        if (response['status'] == "success" || response['success'] == true) {
          _showSuccessDialog();
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Có lỗi xảy ra, vui lòng thử lại';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể kết nối đến server. Vui lòng thử lại sau.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 32,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gửi yêu cầu thành công!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Yêu cầu rút tiền của bạn đã được gửi. Vui lòng chờ xử lý.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConfig.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text(
                      'Trở lại',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,

                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (_errorMessage != null) {
    //   return Scaffold(
    //     backgroundColor: Colors.white,
    //     appBar: _buildAppBar(),
    //     body: Center(
    //       child: Padding(
    //         padding: const EdgeInsets.all(24),
    //         child: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Container(
    //               width: 80,
    //               height: 80,
    //               decoration: BoxDecoration(
    //                 color: Colors.red.shade50,
    //                 shape: BoxShape.circle,
    //               ),
    //               child: Icon(
    //                 Icons.error_outline_rounded,
    //                 size: 40,
    //                 color: Colors.red.shade400,
    //               ),
    //             ),
    //             const SizedBox(height: 20),
    //             Text(
    //               _errorMessage!,
    //               textAlign: TextAlign.center,
    //               style: const TextStyle(
    //                 fontSize: 16,
    //                 color: Color(0xFF1A1A1A),
    //               ),
    //             ),
    //             const SizedBox(height: 24),
    //             SizedBox(
    //               width: 200,
    //               height: 48,
    //               child: ElevatedButton(
    //                 onPressed: () => context.pop(),
    //                 style: ElevatedButton.styleFrom(
    //                   backgroundColor: const Color(0xFF0066FF),
    //                   foregroundColor: Colors.white,
    //                   shape: RoundedRectangleBorder(
    //                     borderRadius: BorderRadius.circular(12),
    //                   ),
    //                 ),
    //                 child: const Text('Quay lại'),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   );
    // }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Section
            _buildInfoSection(),

            const SizedBox(height: 32),

            // Amount Section
            _buildAmountSection(),

            const SizedBox(height: 40),

            // Confirm Button
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Xác nhận rút tiền",
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin tài khoản',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE8ECF0),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.account_balance_rounded,
                label: 'Ngân hàng',
                value: widget.data!['bankName'],
              ),
              const SizedBox(height: 16),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.numbers_rounded,
                label: 'Số tài khoản',
                value: widget.data!['accountNumber'],
              ),
              const SizedBox(height: 16),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.person_rounded,
                label: 'Chủ tài khoản',
                value: widget.data!['accountHolder'],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    final double amount = double.tryParse(widget.data['amount'].toString()) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiết rút tiền',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF0)),
          ),
          child: Column(
            children: [
              _buildAmountRow('Số tiền yêu cầu', amount),
              const SizedBox(height: 12),
              _buildAmountRow(
                'Phí rút tiền (${_feePercentWithdraw}%)',
                _feeAmount,
                note: _hasFirstWithdrawalToday ? '(Miễn phí lần đầu trong ngày)' : null,
                isFee: true,
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFE8ECF0)),
              _buildAmountRow('Thực nhận', _netAmount, isNet: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, double value, {String? note, bool isFee = false, bool isNet = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isNet ? FontWeight.w600 : FontWeight.w500,
                  color: isNet ? ColorConfig.primary : const Color(0xFF4A5568),
                ),
              ),
              if (note != null)
                Text(
                  note,
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
            ],
          ),
        ),
        Row(
          children: [
            if(isFee) ...[
              Text(
                '- ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isNet ? FontWeight.bold : FontWeight.w600,
                  color: isNet ? ColorConfig.primary : (isFee ? Colors.red.shade600 : const Color(0xFF1A1A1A)),
                ),
              ),
            ],
            Text(
              '${_formatAmount(value.toString())} đ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: isNet ? FontWeight.bold : FontWeight.w600,
                color: isNet ? ColorConfig.primary : (isFee ? Colors.red.shade600 : const Color(0xFF1A1A1A)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleConfirmWithdraw,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConfig.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Xác nhận yêu cầu rút tiền',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thời gian xử lý giao dịch từ 24-48 giờ làm việc',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE8ECF0),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: ColorConfig.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFE8ECF0),
    );
  }

  String _formatAmount(String amount) {
    try {
      final number = double.parse(amount);
      final formatter = NumberFormat('#,###');
      return formatter.format(number);
    } catch (e) {
      return amount;
    }
  }
}