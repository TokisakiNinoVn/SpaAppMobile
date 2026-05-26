import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/order_helper.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/order_provider.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/screens/widgets/date_of_birth_picker_bottom_sheet.dart';
import 'package:spa_app/services/service_service.dart';
import 'package:intl/intl.dart';

class ManagementPostOrder extends StatefulWidget {
  const ManagementPostOrder({super.key});

  @override
  State<ManagementPostOrder> createState() => _ManagementPostOrderState();
}

class _ManagementPostOrderState extends State<ManagementPostOrder> {
  final ServiceService _serviceService = ServiceService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  List _listPost = [];
  List _originalListPost = [];
  List<dynamic> allServices = [];

  // Filter state
  String _statusQuery = 'pending';
  String _searchKeyword = '';
  String? _selectedServiceId;   // null = Tất cả dịch vụ
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAllServices();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadListPost();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------- API ----------

  Future<void> _loadListPost() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final parts = <String>[];
      if (_statusQuery.isNotEmpty) parts.add('status=$_statusQuery');
      parts.add('date=$dateStr');
      if (_selectedServiceId != null && _selectedServiceId!.isNotEmpty) {
        parts.add('serviceId=$_selectedServiceId');
      }
      final queryParams = parts.join('&');

      final provider = context.read<OrderProvider>();
      final success = await provider.loadListPostOrderAdmin(queryParams);
      if (success && mounted) {
        setState(() {
          _originalListPost = List.from(provider.listPost);
          _applySearchFilter();
        });
      }
    } catch (e) {
      appLog('Lỗi load bài đăng: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllServices() async {
    try {
      final response = await _serviceService.listService();
      if (mounted) {
        setState(() {
          allServices = response['data'] ?? [];
        });
      }
    } catch (e) {
      appLog('Error loading services: $e');
    }
  }

  // ---------- Search ----------

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchKeyword = value.trim();
        _applySearchFilter();
      });
    });
  }

  void _applySearchFilter() {
    if (_searchKeyword.isEmpty) {
      _listPost = List.from(_originalListPost);
    } else {
      final keyword = _searchKeyword.toLowerCase();
      _listPost = _originalListPost.where((order) {
        final phone = (order['phoneCustomer'] ?? '').toLowerCase();
        final address = (order['address'] ?? '').toLowerCase();
        return phone.contains(keyword) || address.contains(keyword);
      }).toList();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchKeyword = '';
      _applySearchFilter();
    });
  }

  // ---------- Filters ----------

  void _resetFilters() {
    setState(() {
      _statusQuery = 'pending';
      _selectedServiceId = null;
      _selectedDate = DateTime.now();
    });
    _loadListPost();
  }

  // Sử dụng BottomSheet để chọn ngày (thay vì showDatePicker)
  Future<void> _pickDateWithBottomSheet() async {
    final picked = await showDateOfBirthPickerBottomSheet(
      context: context,
      initialDate: _selectedDate,
      minimumDate: DateTime(2000),      // Có thể điều chỉnh theo nhu cầu
      maximumDate: DateTime(2100),
      title: "Chọn ngày",
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadListPost();
    }
  }

  // ---------- Helpers ----------

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
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
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  bool get _hasActiveFilters =>
      _statusQuery != 'pending' ||
          _selectedServiceId != null ||
          !_isSameDay(_selectedDate, DateTime.now());

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConfig.primaryBackground,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            // Back button
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
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Search field
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo địa chỉ, số điện thoại...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    suffixIcon: _searchKeyword.isNotEmpty
                        ? GestureDetector(
                      onTap: _clearSearch,
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                    )
                        : null,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: ColorConfig.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await context.push<bool>(
              AdminRouterConfig.createOrderPost,
            );
            if (result == true) _loadListPost();
          },
          backgroundColor: ColorConfig.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, size: 22),
          ),
          label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "Tạo mới",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Column(
        children: [
          // ── Filter row ──────────────────────────────────────────────
          _buildFilterRow(),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _listPost.length,
              itemBuilder: (context, index) =>
                  _buildOrderCard(_listPost[index]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Filter row (đã thêm chip chọn ngày) ----------

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      color: ColorConfig.primaryBackground,
      child: Row(
        children: [
          // Status dropdown
          Expanded(child: _buildStatusDropdown()),

          const SizedBox(width: 3),

          // Service dropdown
          Expanded(child: _buildServiceDropdown()),

          const SizedBox(width: 3),

          // Date picker chip (dùng BottomSheet)
          _buildDateChip(),

          const SizedBox(width: 3),

          // Reset button
          _buildResetButton(),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final options = {
      'pending': 'Đang chờ',
      'expired': 'Hết hạn',
      'all': 'Tất cả',
    };

    return _buildDropdownChip<String>(
      value: _statusQuery,
      items: options.entries
          .map(
            (e) => DropdownMenuItem(
          value: e.key,
          child: Text(e.value, style: const TextStyle(fontSize: 13)),
        ),
      )
          .toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() => _statusQuery = val);
        _loadListPost();
      },
      hint: 'Trạng thái',
    );
  }

  Widget _buildServiceDropdown() {
    return _buildDropdownChip<String>(
      value: _selectedServiceId,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Loại dịch vụ', style: TextStyle(fontSize: 13)),
        ),
        ...allServices.map<DropdownMenuItem<String>>((s) {
          return DropdownMenuItem<String>(
            value: s['_id']?.toString() ?? '',
            child: SizedBox(
              width: double.infinity,
              child: Text(
                s['name']?.toString() ?? '',
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          );
        }),
      ],
      onChanged: (val) {
        setState(() => _selectedServiceId = val);
        _loadListPost();
      },
      hint: 'Dịch vụ',
    );
  }

  Widget _buildDropdownChip<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String hint,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Chip chọn ngày – khi nhấn sẽ mở BottomSheet
  Widget _buildDateChip() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final label = isToday
        ? 'Hôm nay'
        : DateFormat('dd/MM/yyyy').format(_selectedDate);

    return GestureDetector(
      onTap: _pickDateWithBottomSheet,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isToday ? Colors.grey.shade100 : ColorConfig.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? Colors.grey.shade200 : ColorConfig.primary.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isToday ? Colors.grey.shade600 : ColorConfig.primary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isToday ? Colors.grey.shade700 : ColorConfig.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: _hasActiveFilters ? _resetFilters : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: _hasActiveFilters
              ? ColorConfig.primary.withOpacity(0.10)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hasActiveFilters
                ? ColorConfig.primary.withOpacity(0.35)
                : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          Icons.refresh_rounded,
          size: 18,
          color: _hasActiveFilters ? ColorConfig.primary : Colors.grey.shade400,
        ),
      ),
    );
  }

  // ---------- Order card ----------

  Widget _buildOrderCard(dynamic order) {
    final statusColor = _getStatusColor(order['status'] ?? '');
    final totalApplicants = order['totalApplicants'] ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        context.push(
          AdminRouterConfig.listTechnicianApply,
          extra: order,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Status + Priority + Apply count
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // STATUS
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        OrderHelper.displayStatusOrder(
                                          order['status'],
                                        ),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: statusColor,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // PRIORITY
                                if (order['isPrioritize'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ColorConfig.white,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                          color: ColorConfig.primary),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.flash_on_rounded,
                                          size: 14,
                                          color: ColorConfig.textPrimary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Ưu tiên",
                                          style: TextStyle(
                                            color: ColorConfig.textPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // APPLY COUNT
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: ColorConfig.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  ColorConfig.primary.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(
                                    "KTV ứng: ",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ColorConfig.textWhite
                                          .withOpacity(0.95),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$totalApplicants",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConfig.textWhite,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// SERVICE NAME
                      Text(
                        order['nameService'] ?? 'Không có tên',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// INFO CHIPS
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            label:
                            "${order['serviceTimePriceDetails']['duration'] ?? 0} phút",
                          ),
                          _buildInfoChip(
                            label:
                            "${FormatHelper.formatPrice(order['pricing']['serviceAmount'] ?? 0)} đ",
                          ),
                          if ((order['pricing']['extraAmount'] ?? 0) > 0)
                            _buildInfoChip(
                              icon: Icons.flash_on_rounded,
                              label:
                              "${FormatHelper.formatPrice(order['pricing']['extraAmount'] ?? 0)} đ",
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ADDRESS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['address'] ?? 'Không có địa chỉ',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// GENDER + PHONE
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  order['genderRequirement'] == 'female'
                      ? 'Yêu cầu nữ'
                      : 'Yêu cầu nam',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const Spacer(),
                Icon(Icons.phone_outlined,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  order['phoneCustomer'] ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),

            /// PRICE
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "KTV nhận được (- ${order['pricing']?['platformFeePercent'] ?? 0}% phí)",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(
                          order['pricing']?['technicianReceiveAmount'] ?? 0,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConfig.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Tổng thanh toán",
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(
                        order['pricing']?['finalAmount'] ??
                            order['price'] ??
                            0,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({IconData? icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConfig.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ColorConfig.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: ColorConfig.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColorConfig.primary,
            ),
          ),
        ],
      ),
    );
  }
}