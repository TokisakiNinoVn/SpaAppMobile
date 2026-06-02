import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/services/deposit_service.dart';
import 'package:spa_app/utils/clipboard_util.dart';
import 'package:spa_app/utils/image_download_util.dart';

import 'package:spa_app/storage/index.dart';

class QRCodeScreen extends StatefulWidget {
  final int amount;
  const QRCodeScreen({
    super.key,
    required this.amount,
  });

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  final DepositService _depositService = DepositService();
  bool _isLoadingQR = true;
  bool _isConfirming = false;
  bool _isCancelling = false;
  bool _isActionCompleted = false;
  String? _qrImageUrl;
  String? _qrCode;
  String? _depositId;
  String? _errorMessage;

  Map<String, dynamic> responseCreateQR = {};

  // ── Polling ──────────────────────────────────────────────
  Timer? _pollingTimer;
  bool _isPolling = false; // guard: chặn concurrent calls
  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _createQR();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  // ── Polling helpers ───────────────────────────────────────

  void _startPolling() {
    _stopPolling(); // đảm bảo không có timer cũ
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollVerifyDeposit();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollVerifyDeposit() async {
    if (_isPolling || _depositId == null || _isActionCompleted) return;
    _isPolling = true;

    try {
      // Build query string từ depositId (server tự map sang code + amount)
      // Demo: depositId=6a1ea1fe79a3aff9804d4452&code=RH8ZRAPQT5U&amount=4000&createdAt=2026-06-02T09:27:26.094+00:00&numberBank=100874628145
      // appLog("responseCreateQR: $responseCreateQR");
      final query = "depositId=$_depositId&code=${responseCreateQR['code']}&amount=${responseCreateQR['amount']}&createdAt=${responseCreateQR['createdAt']}&numberBank=${responseCreateQR['bankReceivingDetails']['accountNumber']}";
      // appLog("query: $query");
      // return;
      final response = await _depositService.verifyDeposit(query);

      // appLog("Poll verify response: ${response['success']}");
      // appLog("Response: ${response}");
      // Kiểm tra success + verified = true
      final isSuccess = response['success'] == true;
      final data = response['data'];
      final isVerified = data != null && (data['verified'] == true);

      if (isSuccess && isVerified && mounted) {
        _stopPolling();

        setState(() {
          _isActionCompleted = true;
        });

        // // Cập nhật balance nếu có
        // final newBalance = data['new_balance'] ?? data['balance'];
        // if (newBalance != null) {
        //   await SharedPrefs.saveValue(PrefType.int, "balance", newBalance);
        // }

        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            "Nạp tiền thành công. Số dư sẽ được cập nhật trong giây lát.",
          );

          await Future.delayed(const Duration(milliseconds: 800));

          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      // Lỗi mạng / timeout → bỏ qua, tiếp tục poll ở lần sau
      appLog("Poll error (ignored): $e");
    } finally {
      _isPolling = false;
    }
  }

  // ─────────────────────────────────────────────────────────

  Future<void> _initializeNotifications() async {
    await ImageDownloadUtil.initializeNotifications();
  }

  Future<void> _createQR() async {
    _stopPolling();
    setState(() {
      _isLoadingQR = true;
      _errorMessage = null;
      _isActionCompleted = false;
    });

    try {
      final response = await _depositService.createQR({
        "amount": widget.amount,
      });

      appLog("response: $response");

      if (response['status'] == 'success') {
        final data = response['data'];
        responseCreateQR = data;
        appLog("responseCreateQR _createQR: $responseCreateQR");

        setState(() {
          _qrImageUrl = data['qrUrl'];
          _qrCode = data['code'];
          _depositId = data['id'];
          _isLoadingQR = false;
        });

        // ← Bắt đầu polling ngay sau khi có depositId
        _startPolling();
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Không thể tạo mã QR';
          _isLoadingQR = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Có lỗi xảy ra: $e';
        _isLoadingQR = false;
      });
    }
  }

  Future<void> _saveQRCodeToDevice() async {
    if (_qrImageUrl == null) return;

    final fullImageUrl = FormatHelper.formatNetworkImageUrl(_qrImageUrl!);
    appLog("fullImageUrl: $fullImageUrl");

    await ImageDownloadUtil.downloadImage(
      imageUrl: fullImageUrl,
      context: context,
      onComplete: (success) {
        if (success) {
          appLog("✅ Lưu QR code thành công");
        } else {
          appLog("❌ Lưu QR code thất bại");
        }
      },
    );
  }

  Future<void> _cancelDeposit() async {
    if (_depositId == null) return;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        title: const Text(
          'Xác nhận hủy',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đơn nạp này không?',
          style: TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Quay lại', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    _stopPolling(); // dừng polling trước khi cancel

    setState(() {
      _isCancelling = true;
    });

    try {
      final response = await _depositService.deleteDeposit(_depositId!);

      if (response['status'] == 'success') {
        if (mounted) {
          SnackBarHelper.showWarning(context, "Đã hủy đơn nạp!");
          setState(() {
            _isActionCompleted = true;
          });
          if (mounted) {
            Navigator.pop(context, false);
          }
        }
      } else {
        if (mounted) {
          // resume polling nếu cancel thất bại
          _startPolling();
          SnackBarHelper.showError(context, response['message'] ?? 'Hủy đơn thất bại');
        }
      }
    } catch (e) {
      if (mounted) {
        _startPolling();
        SnackBarHelper.showError(context, "Có lỗi xảy ra khi hủy: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isActionCompleted) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        title: const Text(
          'Xác nhận thoát',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Bạn đang trong quá trình nạp tiền. Nếu thoát khỏi màn hình này, giao dịch sẽ không được xác nhận tại thời điểm hiện tại. Bạn có muốn tiếp tục thoát?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Ở lại', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Vẫn thoát'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          _stopPolling();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              InkWell(
                onTap: _onWillPop,
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
              const Expanded(
                child: Text(
                  "Nạp tiền",
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount card
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 24,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Số tiền nạp',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                          Text(
                            FormatHelper.formatPrice(widget.amount),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: ColorConfig.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              _buildStep(
                number: 1,
                title: "Quét mã QR và hoàn tất thanh toán qua ngân hàng của bạn",
                content: _buildQRContent(),
              ),

              const SizedBox(height: 10),

              _buildStep(
                number: 2,
                title: "Nội dung chuyển khoản",
                content: _buildTransferContent(),
              ),

              const SizedBox(height: 18),

              _buildStep(
                number: 3,
                title: "Hệ thống sẽ tự động xác nhận sau khi nhận được thanh toán",
                content: _buildActionButtons(),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required int number, required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ColorConfig.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: content,
        ),
      ],
    );
  }

  Widget _buildQRContent() {
    if (_isLoadingQR) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)),
              ),
              SizedBox(height: 12),
              Text("Đang tạo mã QR...", style: TextStyle(color: Color(0xFF666666))),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE74C3C)),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF666666)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createQR,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _qrImageUrl != null
                ? Image.network(
              FormatHelper.formatNetworkImageUrl(_qrImageUrl!),
              width: 248,
              height: 248,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code, size: 80, color: Color(0xFF999999)),
                    const SizedBox(height: 8),
                    Text(
                      _qrCode ?? "Mã QR",
                      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                  ],
                );
              },
            )
                : const Icon(Icons.qr_code, size: 120, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 5),
          OutlinedButton.icon(
            onPressed: _saveQRCodeToDevice,
            icon: const Icon(Icons.download_outlined, size: 18, color: Color(0xFF1A1A1A)),
            label: const Text(
              'Lưu mã QR',
              style: TextStyle(color: Color(0xFF1A1A1A)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: const BorderSide(color: Color(0xFFCCCCCC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "SEVQR ${_qrCode ?? "Đang tải..."}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (_qrCode != null)
                  IconButton(
                    onPressed: () => ClipboardUtil.copyToClipboard(context, _qrCode!),
                    icon: const Icon(Icons.copy_outlined, size: 20, color: Color(0xFF666666)),
                    tooltip: "Sao chép",
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Vui lòng nhập chính xác nội dung trên khi chuyển khoản",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Trạng thái đang chờ xác nhận
        if (!_isActionCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Đang chờ xác nhận giao dịch...",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              context.go(CustomerRouterConfig.historyDeposit);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConfig.textWhite,
              backgroundColor: ColorConfig.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: const Text(
              "Xem lịch sử giao dịch",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}