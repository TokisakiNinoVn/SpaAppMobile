import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/enums/gender_customer.dart';
import 'package:spa_app/enums/gender_requirement.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/information_provider.dart';
import 'package:spa_app/providers/service_provider.dart';
import 'package:spa_app/screens/admin/order/components/selected_service_model.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/services/order_service.dart';

// ─────────────────────────────────────────────
// Widget chính
// ─────────────────────────────────────────────
class CreatePostOrder extends StatefulWidget {
  const CreatePostOrder({super.key});

  @override
  State<CreatePostOrder> createState() => _CreatePostOrderState();
}

class _CreatePostOrderState extends State<CreatePostOrder> {
  final OrderService _orderService = OrderService();

  bool _isLoading = true;

  List _services = [];
  SelectedService? _selectedService;
  String _timeType = 'now';
  double valuePlatformFees = 0;

  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _moneyPrioritizeController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 75));

  final _addressFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _moneyFocusNode = FocusNode();

  GenderRequirement _genderRequirement = GenderRequirement.male;
  GenderCustomer _genderCustomer = GenderCustomer.male;

  @override
  void initState() {
    super.initState();
    for (final fn in [_addressFocusNode, _noteFocusNode, _phoneFocusNode, _moneyFocusNode]) {
      fn.addListener(() { if (mounted) setState(() {}); });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadServices();
      await _loadPlatformFees();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    _phoneController.dispose();
    _moneyPrioritizeController.dispose();
    _addressFocusNode.dispose();
    _noteFocusNode.dispose();
    _phoneFocusNode.dispose();
    _moneyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ServiceProvider>();
      final success = await provider.loadListService();
      if (success && mounted) {
        setState(() => _services = provider.serviceBase);
      }
    } catch (e) {
      appLog('Lỗi load services: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPlatformFees() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<InformationProvider>();
      final success = await provider.searchPlatformFees(
        "AUTO_MATCHING",
      );

      if (success && mounted) {
        final fee = provider.platformFee;
        setState(() {
          valuePlatformFees = (fee ?? 0).toDouble();
        });
      }
    } catch (e) {
      appLog('Lỗi load platform fee: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _extraFee => int.tryParse(_moneyPrioritizeController.text.trim()) ?? 0;
  int get _servicePrice => _selectedService?.price ?? 0;
  int get _finalTotal => _servicePrice + _extraFee;
  int get _platformDeductionFee =>(_servicePrice * valuePlatformFees / 100).ceil();
  int get _technicianIncome => (_finalTotal - _platformDeductionFee).ceil();

  bool get _isValidBookingTime {
    if (_timeType != 'book') return true;
    final now = DateTime.now();
    return _selectedDateTime.isAfter(now.add(const Duration(minutes: 60))) &&
        _selectedDateTime.isBefore(now.add(const Duration(days: 7)));
  }

  bool get _canSubmit =>
      _selectedService != null &&
      _addressController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      _isValidBookingTime;

  void _openServicePicker() {
    if (_services.isEmpty) {
      SnackBarHelper.showError(context, 'Danh sách dịch vụ chưa tải được');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServicePickerSheet(
        services: _services,
        selectedTimePriceId: _selectedService?.timePriceId,
        onSelected: (selected) => setState(() => _selectedService = selected as SelectedService?),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final minDateTime = now.add(const Duration(minutes: 60));
    final date = await showDatePicker(
      context: context,
      initialDate: minDateTime,
      firstDate: minDateTime,
      lastDate: now.add(const Duration(days: 7)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: ColorConfig.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(minDateTime),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: ColorConfig.primary),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (selected.isBefore(minDateTime)) {
      _showTimeError('Thời gian đặt trước phải sau thời điểm hiện tại ít nhất 60 phút.');
      return;
    }
    if (selected.isAfter(now.add(const Duration(days: 7)))) {
      _showTimeError('Thời gian đặt trước không được quá 7 ngày.');
      return;
    }
    setState(() => _selectedDateTime = selected);
  }

  void _showTimeError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thời gian không hợp lệ'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  String _getWorkingHours() {
    if (_timeType == 'now') {
      return FormatHelper.formatDateTimeTypeDateTime(DateTime.now().add(const Duration(minutes: 20)));
    }
    return FormatHelper.formatDateTimeTypeDateTime(_selectedDateTime);
  }

  Future<void> _checkCanCreateOrder() async {
    final missing = _missingFields;
    SnackBarHelper.showWarning(
      context,
      "Thiếu: ${missing.join(', ')}",
    );
  }

  List<String> get _missingFields {
    final List<String> fields = [];
    if (_selectedService == null) {
      fields.add("dịch vụ");
    }
    if (_addressController.text.trim().isEmpty) {
      fields.add("địa chỉ");
    }
    if (_phoneController.text.trim().isEmpty) {
      fields.add("số điện thoại");
    }
    if (!_isValidBookingTime) {
      fields.add("thời gian đặt lịch hợp lệ");
    }
    return fields;
  }


  Future<void> _createOrder() async {
    if (_selectedService == null) return;
    final data = {
      'typeOrder': 'automatic-matching',
      'serviceTimePriceId': _selectedService!.timePriceId,
      'nameService': _selectedService!.serviceName,
      'address': _addressController.text.trim(),
      'noteCustomer': _noteController.text.trim(),
      'phoneCustomer': _phoneController.text.trim(),
      'moneyPrioritize': int.tryParse(_moneyPrioritizeController.text.trim()) ?? 0,
      'workingHours': _getWorkingHours(),
      "paymentMethod": "cash",

      'subTypeOrder': _timeType,
      'genderRequirement': _genderRequirement.value,
      'genderCustomer': _genderCustomer.value,
    };
    try {
      // appLog("Data after send: $data");
      // SnackBarHelper.showSuccess(context, 'Tạo yêu cầu đơn thành công! Vui lòng chờ kỹ thuật viên phản hồi!');
      // context.pop(true);
      // return;
      final response = await _orderService.createOrderAdmin(data);
      if (!mounted) return;
      if (response['success'] == true) {
        SnackBarHelper.showSuccess(context, 'Tạo yêu cầu đơn thành công! Vui lòng chờ kỹ thuật viên phản hồi!');
        context.pop(true);
      } else {
        SnackBarHelper.showError(context, response['message'] ?? 'Không thể tạo đơn hàng');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Lỗi tạo đơn: $e');
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: ColorConfig.primary))
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          // padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildServiceCard(),
            const SizedBox(height: 12),
            _buildOrderInfoCard(),
            const SizedBox(height: 12),
            _buildPaymentCard(),
            const SizedBox(height: 12),
            _buildNoteCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF6F7FB),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
          ),
          const SizedBox(width: 12),
          const Text(
            'Tạo đơn việc',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_timeType == 'book' && !_isValidBookingTime)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 16),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Thời gian đặt trước phải sau ít nhất 60 phút',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade100,
                ),
              ),
              child: Row(
                children: [

                  // Button
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _createOrder : _checkCanCreateOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSubmit ? ColorConfig.primary : Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey.shade500,
                          elevation: _canSubmit ? 4 : 0,
                          shadowColor: ColorConfig.primary.withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              child: const Icon(
                                Icons.send_rounded,
                                size: 16,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Flexible(
                              child: Text(
                                _canSubmit
                                    ? 'Đăng đơn tìm KTV'
                                    : 'Chưa đủ thông tin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Card: Chọn dịch vụ
  // ─────────────────────────────────────────────
  Widget _buildServiceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Gói dịch vụ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openServicePicker,
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConfig.primary,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    _selectedService == null
                        ? 'Chọn dịch vụ'
                        : 'Thay đổi',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedService != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ColorConfig.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timer_rounded,
                      color: ColorConfig.primary,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedService!.serviceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          '${_selectedService!.duration} phút',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '${FormatHelper.formatPrice(_selectedService!.price)} đ',
                    style: TextStyle(
                      color: ColorConfig.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Chưa chọn dịch vụ',
                style: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================== SỐ ĐIỆN THOẠI =====================
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(Icons.phone_rounded, size: 18, color: ColorConfig.primary),
                const SizedBox(width: 8),
                const Text(
                  'Số điện thoại',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Nhập số điện thoại khách hàng',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.black38, // mờ hơn
                    fontWeight: FontWeight.w400,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Icon(Icons.person_search_rounded,
                    size: 18, color: ColorConfig.primary),
                const SizedBox(width: 8),
                const Text(
                  'Giới tính khách',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GenderCustomer.values.map((genderCustomer) {
                final isSelected = _genderCustomer == genderCustomer;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _genderCustomer = genderCustomer;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1.5,
                        color: isSelected
                            ? ColorConfig.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          genderCustomer == GenderCustomer.male
                              ? Icons.male_rounded
                              : genderCustomer == GenderCustomer.female
                              ? Icons.female_rounded
                              : Icons.people_alt_rounded,
                          size: 16,
                          color: isSelected
                              ? ColorConfig.primary
                              : Colors.grey,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          genderCustomer.label,
                          style: TextStyle(
                            color: isSelected
                                ? ColorConfig.primary
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ===================== ĐỊA CHỈ =====================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 18, color: ColorConfig.primary),
                const SizedBox(width: 8),
                const Text(
                  'Địa chỉ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      focusNode: _addressFocusNode,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Đường 13, xã Xuân Giang, tỉnh Ninh Bình',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.black38, // mờ hơn
                          fontWeight: FontWeight.w400,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.content_paste_rounded,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    tooltip: 'Dán từ bộ nhớ',
                    onPressed: () async {
                      final data =
                      await Clipboard.getData(Clipboard.kTextPlain);

                      if (data?.text != null) {
                        setState(() {
                          _addressController.text = data!.text!;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // ===================== YÊU CẦU KTV =====================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Icon(Icons.person_search_rounded,
                    size: 18, color: ColorConfig.primary),
                const SizedBox(width: 8),
                const Text(
                  'Yêu cầu KTV',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GenderRequirement.values.map((g) {
                final isSelected = _genderRequirement == g;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _genderRequirement = g;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1.5,
                        color: isSelected
                            ? ColorConfig.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          g == GenderRequirement.male
                              ? Icons.male_rounded
                              : g == GenderRequirement.female
                              ? Icons.female_rounded
                              : Icons.people_alt_rounded,
                          size: 16,
                          color: isSelected
                              ? ColorConfig.primary
                              : Colors.grey,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          g.label,
                          style: TextStyle(
                            color: isSelected
                                ? ColorConfig.primary
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ===================== THỜI GIAN =====================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 18, color: ColorConfig.primary),
                const SizedBox(width: 8),
                const Text(
                  'Thời gian thực hiện',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _timeType = 'now';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: 1.5,
                              color: _timeType == 'now'
                                  ? ColorConfig.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flash_on_rounded,
                                size: 18,
                                color: _timeType == 'now'
                                    ? ColorConfig.primary
                                    : Colors.grey,
                              ),

                              const SizedBox(width: 6),

                              Text(
                                'Đặt ngay',
                                style: TextStyle(
                                  color: _timeType == 'now'
                                      ? ColorConfig.primary
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _timeType = 'book';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: 1.5,
                              color: _timeType == 'book'
                                  ? ColorConfig.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: _timeType == 'book'
                                    ? ColorConfig.primary
                                    : Colors.grey,
                              ),

                              const SizedBox(width: 6),

                              Text(
                                'Chọn giờ khác',
                                style: TextStyle(
                                  color: _timeType == 'book'
                                      ? ColorConfig.primary
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_timeType == 'book') ...[
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: ColorConfig.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                FormatHelper.formatDateTimeTypeDateTime(_selectedDateTime),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (!_isValidBookingTime)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Phải sau hiện tại ít nhất 60 phút và không quá 7 ngày',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),

          // ===================== PHÍ HỖ TRỢ =====================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Icon(Icons.card_giftcard_rounded,
                    size: 18, color: ColorConfig.primary),
                const SizedBox(width: 8),
                const Text(
                  'Phí hỗ trợ thêm',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message:
                  'Khoản tiền hỗ trợ thêm cho kỹ thuật viên (không bắt buộc)',
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _moneyPrioritizeController,
                      focusNode: _moneyFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Text(
                      'đ',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Card: Chi tiết thanh toán
  // ─────────────────────────────────────────────
  Widget _buildPaymentCard() {
    return _Card(
      child: Column(
        children: [
          _CardHeader(icon: Icons.receipt_long_rounded, title: 'Chi tiết thanh toán'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _PaymentRow(
                  label: 'Giá dịch vụ',
                  value: _selectedService != null ? '${FormatHelper.formatPrice(_servicePrice)} đ' : '—',
                ),
                if (_extraFee > 0) ...[
                  const SizedBox(height: 8),
                  _PaymentRow(
                    label: 'Phí hỗ trợ thêm',
                    value: '+${FormatHelper.formatPrice(_extraFee)} đ',
                    valueColor: Colors.green,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _PaymentRow(
                  label: 'Tổng khách cần thanh toán',
                  value: '${FormatHelper.formatPrice(_finalTotal)} đ',
                  isTotal: true,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _PaymentRow(
                        label: 'Phí thu nền tảng (${valuePlatformFees}%)',
                        value: '- ${FormatHelper.formatPrice(_platformDeductionFee)} đ',
                        valueColor: Colors.red,
                      ),
                      Row(
                        children: [
                          Icon(Icons.handshake_rounded, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Thu nhập KTV (ước tính)',
                            style: TextStyle(fontSize: 13, color: Colors.green.shade800),
                          ),
                          const Spacer(),
                          Text(
                            _selectedService != null ? '${FormatHelper.formatPrice(_technicianIncome)} đ' : '—',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Card: Ghi chú
  // ─────────────────────────────────────────────
  Widget _buildNoteCard() {
    return _Card(
      child: Column(
        children: [
          _CardHeader(icon: Icons.edit_note_rounded, title: 'Ghi chú'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _FieldBox(
              child: TextField(
                controller: _noteController,
                focusNode: _noteFocusNode,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ví dụ: thời gian phù hợp, tình trạng cụ thể, lưu ý khi đến…',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable sub-widgets (pure Material, no custom lib)
// ─────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData? icon;
  final String title;
  final Widget? trailing;
  final bool required;

  const _CardHeader({
    this.icon,
    required this.title,
    this.trailing,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 10),
      child: Row(
        children: [
          if(icon != null)Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          if (required)
            Text(' *', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final Widget child;
  const _FieldBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: child,
    );
  }
}

class _TimeTypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final VoidCallback onTap;

  const _TimeTypeChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ColorConfig.primary.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? ColorConfig.primary : Colors.grey.shade200),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(Icons.radio_button_checked_rounded, size: 14, color: ColorConfig.primary)
              else
                Icon(Icons.radio_button_off_rounded, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? ColorConfig.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  const _PaymentRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            color: isTotal ? const Color(0xFF1A1A1A) : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 17 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: valueColor ?? (isTotal ? const Color(0xFF1A1A1A) : Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1A1A)),
      ),
    );
  }
}

// ═════════════════════════════════════════════════
// Bottom sheet: Chọn dịch vụ
// ═════════════════════════════════════════════════
class _ServicePickerSheet extends StatefulWidget {
  final List services;
  final String? selectedTimePriceId;
  final ValueChanged<SelectedService> onSelected;

  const _ServicePickerSheet({
    required this.services,
    required this.selectedTimePriceId,
    required this.onSelected,
  });

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const Text('Chọn dịch vụ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: widget.services.length,
                itemBuilder: (_, i) {
                  final service = widget.services[i];
                  final timePrices = (service['timePrices'] as List?) ?? [];
                  final isExpanded = _expandedIndex == i;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ColorConfig.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.spa_rounded, color: ColorConfig.primary, size: 20),
                        ),
                        title: Text(service['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${timePrices.length} mốc thời gian', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        trailing: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
                        ),
                        onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            children: timePrices.map((tp) {
                              final isSelected = tp['_id'] == widget.selectedTimePriceId;
                              return GestureDetector(
                                onTap: () {
                                  widget.onSelected(SelectedService(
                                    serviceId: service['_id'] ?? '',
                                    serviceName: service['name'] ?? '',
                                    timePriceId: tp['_id'] ?? '',
                                    duration: (tp['duration'] as num?)?.toInt() ?? 0,
                                    price: (tp['price'] as num?)?.toInt() ?? 0,
                                  ));
                                  Navigator.pop(context);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? ColorConfig.primary.withOpacity(0.08) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? ColorConfig.primary : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time_rounded, size: 16, color: isSelected ? ColorConfig.primary : Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${tp['duration']} phút',
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                          color: isSelected ? ColorConfig.primary : Colors.black87,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${FormatHelper.formatPrice((tp['price'] as num?)?.toInt() ?? 0)} đ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? ColorConfig.primary : Colors.black87,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.check_circle_rounded, color: ColorConfig.primary, size: 18),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      if (!isExpanded) const Divider(height: 1, indent: 20, endIndent: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}