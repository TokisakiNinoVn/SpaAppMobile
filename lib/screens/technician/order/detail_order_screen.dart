import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/order_helper.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/order_provider.dart';
import 'package:spa_app/providers/selected_tab_provider.dart';
import 'package:spa_app/routes/config/technician_router_config.dart';
import 'package:spa_app/screens/components/dashed_divider_component.dart';
import 'package:spa_app/screens/customer/tabs/components/SpaDialog.dart';
import 'package:spa_app/screens/technician/tabs/components/accept_order_dialog.dart';
import 'package:spa_app/screens/technician/tabs/components/reject_order_bottom_sheet.dart';
import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'dart:async';

import '../../../storage/index.dart';

class DetailsOrderTechnician extends StatefulWidget {
  final String id;
  final bool isNewOrder;

  const DetailsOrderTechnician({
    super.key,
    required this.id,
    this.isNewOrder = false,
  });

  @override
  State<DetailsOrderTechnician> createState() => _DetailsOrderTechnicianState();
}

class _DetailsOrderTechnicianState extends State<DetailsOrderTechnician> {
  final OrderService _orderService = OrderService();
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = true;
  String _errorMessage = '';
  bool isLoading = true;
  Timer? _timer;
  bool isWorking = false;

  // Tracks open dialogs so we can close them when order expires
  final List<BuildContext> _openDialogContexts = [];

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _rejectReasonController = TextEditingController();

  Duration _remainingTime = const Duration(minutes: 30);
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  // ─── Computed properties ────────────────────────────────────────────────────

  /// Đơn do admin tạo => chế độ ứng tuyển
  bool get _isAdminCreate => _orderDetails?['isAdminCreate'] == true;

  /// Loại đơn
  String get _typeOrder => _orderDetails?['typeOrder'] ?? '';
  String get _subTypeOrder => _orderDetails?['subTypeOrder'] ?? '';

  /// Có thể nhận/ứng tuyển không
  bool get _canHandleOrder {
    if (_isExpired) return false;
    // Đang làm việc + order-now => không cho nhận (chỉ block chế độ nhận việc)
    if (isWorking && !_isAdminCreate && _typeOrder == 'order-now') return false;
    return true;
  }

  /// Text nút hành động chính
  String get _actionButtonText {
    if (_isAdminCreate) return 'Ứng tuyển';
    if (isWorking && _typeOrder == 'order-now') return 'Đang làm việc';
    return 'Nhận việc';
  }

  // ─── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadOrderDetails() async {
    isWorking = await SharedPrefs.getValue(PrefType.bool, "isWorking") ?? false;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      final response = await _orderService.detailOrder(widget.id);
      if (response['success'] == true) {
        setState(() {
          _orderDetails = response['data'];
          _isLoading = false;
        });
        _startCountdown();
      } else {
        throw Exception(response['message'] ?? 'Không thể tải chi tiết đơn');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─── Countdown ───────────────────────────────────────────────────────────────

  void _startCountdown() {
    if (!widget.isNewOrder) return;

    final createdAtStr = _orderDetails!['createdAt'] as String?;
    if (createdAtStr == null) {
      setState(() => _isExpired = true);
      return;
    }

    final createdAt = DateTime.parse(createdAtStr).toLocal();
    final deadline = createdAt.add(const Duration(minutes: 30));
    final now = DateTime.now();

    if (now.isAfter(deadline)) {
      setState(() => _isExpired = true);
      return;
    }

    _remainingTime = deadline.difference(now);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
        setState(() => _isExpired = true);
        _onOrderExpired();
      } else {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      }
    });
  }

  /// Gọi khi đơn hết hạn: đóng tất cả dialog/bottom sheet đang mở
  void _onOrderExpired() {
    // Đóng tất cả dialog đang mở
    for (final ctx in List.of(_openDialogContexts)) {
      if (ctx.mounted) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }
    }
    _openDialogContexts.clear();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00';
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ─── Accept / Reject ─────────────────────────────────────────────────────────
  Future<void> _acceptOrderWithMessage(String message) async {
    try {
      if (_typeOrder == 'order-now' || (_typeOrder == 'automatic-matching' && _subTypeOrder == 'now')) {
        final data = {
          'orderId': widget.id,
          'result': 'approved',
          'noteTechnician': message,
        };
        final response = await _orderService.updateStatus(data);
        if (response['success'] == true) {
          if (!mounted) return;
          final acceptedAt = DateTime.now().toIso8601String();
          await SharedPrefs.saveValue(PrefType.string, "orderDetail", _orderDetails);
          await SharedPrefs.saveValue(PrefType.bool, "isWorking", true);
          await SharedPrefs.saveValue(PrefType.string, "idOrderWorking", widget.id);
          await SharedPrefs.saveValue(PrefType.string, "acceptedAt", acceptedAt);
          SnackBarHelper.showSuccess(context, "Nhận đơn thành công!");
          context.read<SelectedTabProvider>().setIndex(0);
          context.go(TechnicianRouterConfig.homeTechnician);
        }
      } else if (_typeOrder == 'book' || (_typeOrder == 'automatic-matching' && _subTypeOrder == 'book')) {
        final data = {'orderId': widget.id, 'result': 'approved', 'noteTechnician': message };
        final response = await _orderService.updateStatus(data);
        if (response['success'] == true) {
          if (!mounted) return;
          SnackBarHelper.showSuccess(context, "Nhận đơn việc thành công!");
          context.read<SelectedTabProvider>().setIndex(1);
          context.go(TechnicianRouterConfig.homeTechnician);
        } else {
          SnackBarHelper.showError(context, "Lỗi khi nhận đơn!");
        }
      } else {
        SnackBarHelper.showError(context, "Không rõ loại đơn! ${_typeOrder}");
      }
    } catch (e) {
      debugPrint('Error accepting order: $e');
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Có lỗi xảy ra khi nhận đơn');
    }
  }

  Future<void> _rejectOrderWithReason(String? reason) async {
    try {
      final data = {
        'orderId': widget.id,
        'result': 'rejected',
        'noteTechnician': '',
        'reasonReject': reason ?? '',
      };
      final response = await _orderService.updateStatus(data);
      if (response['success'] == true) {
        if (!mounted) return;
        _timer?.cancel();
        SnackBarHelper.showSuccess(context, 'Đã từ chối đơn việc');
      }
    } catch (e) {
      debugPrint('Error rejecting order: $e');
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Có lỗi xảy ra, vui lòng thử lại');
    }
  }

  Future<void> _showConfirmApplyJobDialog(String idOrder) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        _openDialogContexts.add(dialogContext);
        return SpaDialog(
          iconColor: ColorConfig.primary,
          title: 'Xác nhận',
          body: 'Xác nhận ứng tuyển đơn việc?',
          cancelLabel: 'Đóng',
          confirmLabel: 'Xác nhận',
          confirmColor: ColorConfig.primary,
          onConfirm: () {
            // Navigator.pop(dialogContext, true);
          },
        );
      },
    );

    _openDialogContexts.removeWhere((c) => !c.mounted);

    if (result != true || !mounted) return;

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingCtx) {
        _openDialogContexts.add(loadingCtx);
        return Center(
          child: CircularProgressIndicator(color: ColorConfig.primary),
        );
      },
    );

    try {
      final provider = context.read<OrderProvider>();
      final success = await provider.technicianApplyOrder(idOrder);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _openDialogContexts.removeWhere((c) => !c.mounted);

      if (!mounted) return;

      if (success) {
        SnackBarHelper.showSuccess(context, "Ứng tuyển đơn việc thành công!");
      } else {
        SnackBarHelper.showError(context, provider.errorMessage ?? "Ứng tuyển thất bại!");
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _openDialogContexts.removeWhere((c) => !c.mounted);
      if (!mounted) return;
      appLog("Apply order error: $e");
      SnackBarHelper.showError(context, "Ứng tuyển đơn việc thất bại: $e");
    }
  }

  Future<void> _showAcceptOrderDialog() {
    return showDialog(
      context: context,
      builder: (dialogCtx) {
        _openDialogContexts.add(dialogCtx);
        return AcceptOrderDialog(
          onConfirm: (message) async {
            await _acceptOrderWithMessage(message);
          },
        );
      },
    ).then((_) {
      _openDialogContexts.removeWhere((c) => !c.mounted);
    });
  }

  // ─── UI helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic>? get _pricing => _orderDetails?['pricing'];
  Map<String, dynamic>? get _serviceTimePrice => _orderDetails?['serviceTimePrice'];
  Map<String, dynamic>? get _customer => _orderDetails?['customer'];

  Widget _buildSection(String? title, Widget child, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: ColorConfig.primary),
                      const SizedBox(width: 8),
                    ],
                    if (title != null && title.isNotEmpty)
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: ColorConfig.textBlack,
                          letterSpacing: -0.3,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
      String label,
      int amount, {
        bool isTotal = false,
        bool isAdd = false,
        bool isRemove = false,
        bool toolTip = false,
        String? textToolTip,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                  color: isTotal
                      ? ColorConfig.primary
                      : ColorConfig.textBlack.withOpacity(0.8),
                ),
              ),
              if (toolTip && textToolTip != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: textToolTip,
                  triggerMode: TooltipTriggerMode.tap,
                  preferBelow: false,
                  waitDuration: const Duration(milliseconds: 100),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConfig.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              if (isAdd)
                Icon(Icons.add, size: 14, color: ColorConfig.primary)
              else if (isRemove)
                Icon(Icons.remove, size: 14, color: ColorConfig.textError),
              Text(
                "${FormatHelper.formatPrice(amount)} đ",
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                  color: isTotal || isAdd
                      ? ColorConfig.primary
                      : isRemove
                      ? ColorConfig.textError
                      : ColorConfig.textBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ColorConfig.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: ColorConfig.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadOrderDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _orderDetails!;
    final status = order['status'] ?? '';
    final isPrioritize = order['isPrioritize'] ?? false;
    const double allBorderRadius = 20;

    // Điều kiện hiển thị bottom bar hành động
    final bool showActionBar = widget.isNewOrder && status == 'pending' && !_isExpired;
    // appLog("${status}");
    // appLog("$showActionBar | ${widget.isNewOrder} : ${status == 'pending'} : ${!_isExpired}");

    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorConfig.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Chi tiết đơn việc',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: ColorConfig.textBlack,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Scrollable content ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  // Order header card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ColorConfig.white,
                      borderRadius: BorderRadius.circular(allBorderRadius),
                      border: Border.all(
                        color: ColorConfig.primary.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header strip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: ColorConfig.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(allBorderRadius),
                              topRight: Radius.circular(allBorderRadius),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isPrioritize)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFB74D),
                                        Color(0xFFFF9800)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.flash_on,
                                          size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ưu tiên',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  OrderHelper.displayTypeOrder(
                                      order['typeOrder']),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: ColorConfig.textWhite,
                                  ),
                                ),
                              ),
                              // Countdown timer
                              if (widget.isNewOrder)
                                Text(
                                  _formatDuration(_remainingTime),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _remainingTime.inSeconds <= 60
                                        ? Colors.red.shade200
                                        : Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Body
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Service name + duration
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                order['nameService'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (_serviceTimePrice !=
                                                null) ...[
                                              const SizedBox(width: 10),
                                              Container(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: ColorConfig.primary
                                                      .withOpacity(0.08),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      30),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.schedule_rounded,
                                                      size: 14,
                                                      color:
                                                      ColorConfig.primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${_serviceTimePrice!['duration']} phút',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: ColorConfig
                                                            .primary,
                                                        fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const DashedDivider(),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Customer info
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          status != 'done'
                                              ? (_customer?["gender"] ==
                                              "male"
                                              ? "Khách hàng nam"
                                              : "Khách hàng nữ")
                                              : (_customer?["fullname"] ??
                                              "Chưa có tên"),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (status == 'done') ...[
                                          Row(
                                            children: [
                                              Icon(Icons.wc_rounded,
                                                  size: 16,
                                                  color:
                                                  Colors.grey.shade600),
                                              const SizedBox(width: 6),
                                              Text(
                                                _customer?["gender"] ==
                                                    "male"
                                                    ? "Nam"
                                                    : "Nữ",
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                    Colors.grey.shade700),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                        Row(
                                          children: [
                                            Icon(Icons.phone_outlined,
                                                size: 16,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 6),
                                            Text(
                                              status != 'done'
                                                  ? "Chưa hiển thị"
                                                  : (_customer?["phone"] ??
                                                  "Chưa có SĐT"),
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                  Colors.grey.shade700),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                size: 16,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                order['address'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1.5,
                                                  color:
                                                  Colors.grey.shade800,
                                                ),
                                                softWrap: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const DashedDivider(),
                                        const SizedBox(height: 6),

                                        // Notes section
                                        if ((order['noteCustomer'] != null &&
                                            order['noteCustomer']
                                                .toString()
                                                .isNotEmpty) ||
                                            (order['noteTechnician'] !=
                                                null &&
                                                order['noteTechnician']
                                                    .toString()
                                                    .isNotEmpty) ||
                                            (order['reasonReject'] != null &&
                                                order['reasonReject']
                                                    .toString()
                                                    .isNotEmpty)) ...[
                                          const Text(
                                            'Ghi chú',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          if (order['noteCustomer'] != null &&
                                              order['noteCustomer']
                                                  .toString()
                                                  .isNotEmpty)
                                            _buildNoteItem('Khách hàng',
                                                order['noteCustomer']),
                                          if (order['noteTechnician'] !=
                                              null &&
                                              order['noteTechnician']
                                                  .toString()
                                                  .isNotEmpty)
                                            _buildNoteItem(
                                                'KTV', order['noteTechnician']),
                                          if (order['reasonReject'] != null &&
                                              order['reasonReject']
                                                  .toString()
                                                  .isNotEmpty)
                                            _buildNoteItem('Lý do từ chối',
                                                order['reasonReject']),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Pricing card
                  if (_pricing != null)
                    _buildSection(
                      'Chi tiết hóa đơn',
                      Column(
                        children: [
                          _buildPriceRow(
                              'Tổng thanh toán',
                              _pricing!['finalAmount'] ?? 0,
                              isTotal: true),
                          _buildPriceRow(
                              'Giá dịch vụ', _pricing!['serviceAmount'] ?? 0),
                          if ((_pricing!['discountAmount'] ?? 0) > 0)
                            _buildPriceRow(
                                'Ưu đãi', -(_pricing!['discountAmount'] ?? 0),
                                isRemove: true),
                          if ((_pricing!['extraAmount'] ?? 0) > 0)
                            _buildPriceRow('Phụ phí hỗ trợ',
                                _pricing!['extraAmount'] ?? 0,
                                isAdd: true),
                          if ((_pricing!['platformFeePercent'] ?? 0) > 0)
                            _buildPriceRow(
                              'Phí nền tảng',
                              _pricing!['platformFeeAmount'] ?? 0,
                              isRemove: true,
                              toolTip: true,
                              textToolTip:
                              "Khoản phí nền tảng được áp dụng cho mỗi đơn dịch vụ.\nPhí nền tảng áp dụng cho đơn dịch vụ này là: ${FormatHelper.formatPrice(_pricing!['platformFeeAmount'])}đ (${_pricing!['platformFeePercent']}%)",
                            ),
                          const Divider(height: 20, thickness: 1),
                          _buildPriceRow(
                            status == "done"
                                ? 'Số tiền thực nhận'
                                : 'Thu nhập dự kiến',
                            _pricing!['technicianReceiveAmount'] ?? 0,
                            isAdd: true,
                            isTotal: true,
                          ),
                        ],
                      ),
                      icon: Icons.receipt_long,
                    ),
                ],
              ),
            ),
          ),

          // ── Action bar ──────────────────────────────────────────────────────
          if (showActionBar)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Nút từ chối (ẩn với automatic-matching)
                  if (_typeOrder != 'automatic-matching') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          String? reason;

                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (sheetCtx) {
                              _openDialogContexts.add(sheetCtx);
                              return RejectOrderBottomSheet(
                                onConfirm: (r) async {
                                  reason = r;
                                  await _rejectOrderWithReason(r);
                                },
                              );
                            },
                          );

                          _openDialogContexts
                              .removeWhere((c) => !c.mounted);

                          if (reason != null && mounted) {
                            context.pop({'success': true, 'id': widget.id});
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40)),
                        ),
                        child: Text(
                          'Từ chối',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Nút hành động chính (Nhận việc / Ứng tuyển)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canHandleOrder
                          ? () {
                        if (_isAdminCreate) {
                          _showConfirmApplyJobDialog(widget.id);
                        } else {
                          _showAcceptOrderDialog();
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConfig.primary,
                        disabledBackgroundColor:
                        ColorConfig.primary.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _actionButtonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}