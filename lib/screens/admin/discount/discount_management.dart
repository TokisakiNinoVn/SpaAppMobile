import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/discount_service.dart';
import '../../../../helper/snackbar_helper.dart';
import 'package:spa_app/helper/format_helper.dart';

class DiscountManagement extends StatefulWidget {
  const DiscountManagement({super.key});

  @override
  _DiscountManagementState createState() => _DiscountManagementState();
}

class _DiscountManagementState extends State<DiscountManagement> {
  List<Map<String, dynamic>> discounts = [];
  List<Map<String, dynamic>> filteredDiscounts = [];
  bool isLoading = true;

  // Filter controllers
  String searchQuery = '';
  String? selectedIsActive;
  String? selectedTypeDiscount;
  DateTime? startDateFilter;
  DateTime? endDateFilter;

  final TextEditingController searchController = TextEditingController();
  final DiscountService discountService = DiscountService();

  @override
  void initState() {
    super.initState();
    fetchDiscounts();
  }

  Future<void> fetchDiscounts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await discountService.listAdminDiscount();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          discounts = List<Map<String, dynamic>>.from(response['data']);
          filteredDiscounts = discounts;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        SnackbarHelper.showError(context, response['message'] ?? 'Không thể tải danh sách khuyến mãi');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      SnackbarHelper.showError(context, 'Đã xảy ra lỗi khi tải dữ liệu');
    }
  }

  void applyFilters() {
    setState(() {
      filteredDiscounts = discounts.where((discount) {
        // Search filter
        bool matchesSearch = searchQuery.isEmpty ||
            discount['code'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            discount['description'].toString().toLowerCase().contains(searchQuery.toLowerCase());

        // isActive filter
        bool matchesIsActive = selectedIsActive == null ||
            discount['isActive'].toString() == selectedIsActive;

        // typeDiscount filter
        bool matchesTypeDiscount = selectedTypeDiscount == null ||
            discount['typeDiscount'] == selectedTypeDiscount;

        // startAt filter
        bool matchesStartDate = startDateFilter == null ||
            DateTime.parse(discount['startAt']).isAfter(startDateFilter!) ||
            DateTime.parse(discount['startAt']).isAtSameMomentAs(startDateFilter!);

        // expiresAt filter
        bool matchesEndDate = endDateFilter == null ||
            DateTime.parse(discount['expiresAt']).isBefore(endDateFilter!) ||
            DateTime.parse(discount['expiresAt']).isAtSameMomentAs(endDateFilter!);

        return matchesSearch && matchesIsActive && matchesTypeDiscount &&
            matchesStartDate && matchesEndDate;
      }).toList();
    });
  }

  void clearFilters() {
    setState(() {
      searchQuery = '';
      searchController.clear();
      selectedIsActive = null;
      selectedTypeDiscount = null;
      startDateFilter = null;
      endDateFilter = null;
      filteredDiscounts = discounts;
    });
  }

  Future<void> deleteDiscount(String id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa mã khuyến mãi "$code" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await discountService.deleteDiscount(id);
        if (response['success'] == true) {
          SnackbarHelper.showSuccess(context, 'Xóa mã khuyến mãi thành công');
          fetchDiscounts(); // Refresh list
        } else {
          SnackbarHelper.showError(context, response['message'] ?? 'Xóa thất bại');
        }
      } catch (e) {
        SnackbarHelper.showError(context, 'Đã xảy ra lỗi khi xóa');
      }
    }
  }

  void _showFilterBottomSheet() {
    String tempSearchQuery = searchQuery;
    String? tempSelectedIsActive = selectedIsActive;
    String? tempSelectedTypeDiscount = selectedTypeDiscount;
    DateTime? tempStartDateFilter = startDateFilter;
    DateTime? tempEndDateFilter = endDateFilter;
    TextEditingController tempSearchController = TextEditingController(text: searchQuery);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return FractionallySizedBox(

            heightFactor: 0.8,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bộ lọc',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempSearchQuery = '';
                              tempSearchController.clear();
                              tempSelectedIsActive = null;
                              tempSelectedTypeDiscount = null;
                              tempStartDateFilter = null;
                              tempEndDateFilter = null;
                            });
                          },
                          child: Text(
                            'Xóa tất cả',
                            style: TextStyle(
                              color: Colors.red[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 24),

                  // Filter content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search section
                          _buildFilterSection(
                            title: 'Tìm kiếm',
                            icon: Icons.search,
                            child: TextField(
                              controller: tempSearchController,
                              decoration: InputDecoration(
                                hintText: 'Mã khuyến mãi hoặc mô tả...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                setSheetState(() {
                                  tempSearchQuery = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Status section
                          _buildFilterSection(
                            title: 'Trạng thái',
                            icon: Icons.toggle_on,
                            child: Wrap(
                              spacing: 12,
                              children: [
                                _buildFilterOption(
                                  label: 'Tất cả',
                                  value: null,
                                  currentValue: tempSelectedIsActive,
                                  onTap: () => setSheetState(() => tempSelectedIsActive = null),
                                ),
                                _buildFilterOption(
                                  label: 'Đang hoạt động',
                                  value: 'true',
                                  currentValue: tempSelectedIsActive,
                                  onTap: () => setSheetState(() => tempSelectedIsActive = 'true'),
                                ),
                                _buildFilterOption(
                                  label: 'Vô hiệu hóa',
                                  value: 'false',
                                  currentValue: tempSelectedIsActive,
                                  onTap: () => setSheetState(() => tempSelectedIsActive = 'false'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Discount type section
                          _buildFilterSection(
                            title: 'Loại giảm giá',
                            icon: Icons.percent,
                            child: Wrap(
                              spacing: 12,
                              children: [
                                _buildFilterOption(
                                  label: 'Tất cả',
                                  value: null,
                                  currentValue: tempSelectedTypeDiscount,
                                  onTap: () => setSheetState(() => tempSelectedTypeDiscount = null),
                                ),
                                _buildFilterOption(
                                  label: 'Phần trăm',
                                  value: 'percentage',
                                  currentValue: tempSelectedTypeDiscount,
                                  onTap: () => setSheetState(() => tempSelectedTypeDiscount = 'percentage'),
                                ),
                                _buildFilterOption(
                                  label: 'Cố định',
                                  value: 'fixed',
                                  currentValue: tempSelectedTypeDiscount,
                                  onTap: () => setSheetState(() => tempSelectedTypeDiscount = 'fixed'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Date range section
                          _buildFilterSection(
                            title: 'Ngày hiệu lực',
                            icon: Icons.calendar_today,
                            child: Column(
                              children: [
                                _buildDatePickerItem(
                                  label: 'Từ ngày',
                                  date: tempStartDateFilter,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: tempStartDateFilter ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (date != null) {
                                      setSheetState(() {
                                        tempStartDateFilter = date;
                                      });
                                    }
                                  },
                                  onClear: () {
                                    setSheetState(() {
                                      tempStartDateFilter = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildDatePickerItem(
                                  label: 'Đến ngày',
                                  date: tempEndDateFilter,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: tempEndDateFilter ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (date != null) {
                                      setSheetState(() {
                                        tempEndDateFilter = date;
                                      });
                                    }
                                  },
                                  onClear: () {
                                    setSheetState(() {
                                      tempEndDateFilter = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                searchQuery = tempSearchQuery;
                                selectedIsActive = tempSelectedIsActive;
                                selectedTypeDiscount = tempSelectedTypeDiscount;
                                startDateFilter = tempStartDateFilter;
                                endDateFilter = tempEndDateFilter;
                                applyFilters();
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Áp dụng',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildFilterOption({
    required String label,
    required dynamic value,
    required dynamic currentValue,
    required VoidCallback onTap,
  }) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[400]! : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue[700] : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerItem({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  date != null ? FormatHelper.formatDateTimeTypeDateTime(date) : label,
                  style: TextStyle(
                    color: date != null ? Colors.black87 : Colors.grey[600],
                    fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý khuyến mãi", style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_alt_rounded),
                tooltip: "Lọc",
                onPressed: _showFilterBottomSheet,
              ),
              if (selectedIsActive != null ||
                  selectedTypeDiscount != null ||
                  startDateFilter != null ||
                  endDateFilter != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await context.push(AdminRouterConfig.createDiscount);
              if (result == true) {
                fetchDiscounts();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khuyến mãi...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchQuery = '';
                      applyFilters();
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  applyFilters();
                });
              },
            ),
          ),

          // Active filters chips
          if (selectedIsActive != null ||
              selectedTypeDiscount != null ||
              startDateFilter != null ||
              endDateFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Đang lọc: ',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    if (selectedIsActive != null)
                      _buildActiveFilterChip(
                        label: selectedIsActive == 'true' ? 'Đang hoạt động' : 'Vô hiệu hóa',
                        onDelete: () {
                          setState(() {
                            selectedIsActive = null;
                            applyFilters();
                          });
                        },
                      ),
                    if (selectedTypeDiscount != null)
                      _buildActiveFilterChip(
                        label: selectedTypeDiscount == 'percentage' ? 'Phần trăm' : 'Cố định',
                        onDelete: () {
                          setState(() {
                            selectedTypeDiscount = null;
                            applyFilters();
                          });
                        },
                      ),
                    if (startDateFilter != null)
                      _buildActiveFilterChip(
                        label: 'Từ: ${FormatHelper.formatDateTimeTypeDateTime(startDateFilter!)}',
                        onDelete: () {
                          setState(() {
                            startDateFilter = null;
                            applyFilters();
                          });
                        },
                      ),
                    if (endDateFilter != null)
                      _buildActiveFilterChip(
                        label: 'Đến: ${FormatHelper.formatDateTimeTypeDateTime(endDateFilter!)}',
                        onDelete: () {
                          setState(() {
                            endDateFilter = null;
                            applyFilters();
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

          // Result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredDiscounts.length} khuyến mãi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (selectedIsActive != null ||
                    selectedTypeDiscount != null ||
                    startDateFilter != null ||
                    endDateFilter != null)
                  TextButton(
                    onPressed: clearFilters,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: Text(
                      'Xóa tất cả bộ lọc',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Discount list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDiscounts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.discount_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có khuyến mãi nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy thử thay đổi bộ lọc hoặc thêm khuyến mãi mới',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDiscounts.length,
              itemBuilder: (context, index) {
                final discount = filteredDiscounts[index];
                return _buildDiscountCard(discount);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        onDeleted: onDelete,
        deleteIcon: const Icon(Icons.close, size: 16),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildDiscountCard(Map<String, dynamic> discount) {
    final isActive = discount['isActive'] == true;
    final typeDiscount = discount['typeDiscount'];
    final value = discount['value'];
    final valueText = typeDiscount == 'percentage'
        ? '${value}%'
        : FormatHelper.formatPrice(value);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discount['code'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          discount['description'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Hoạt động' : 'Vô hiệu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          valueText,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Đơn tối thiểu: ${FormatHelper.formatPrice(discount['minOrderValue'])}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${FormatHelper.formatDate(discount['startAt'])} - ${FormatHelper.formatDate(discount['expiresAt'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Đã dùng: ${discount['usedCount']}/${discount['maxUses']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (discount['maxUses'] - discount['usedCount'] < 10)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Sắp hết',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push(AdminRouterConfig.editDiscount, extra: discount),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Sửa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => deleteDiscount(discount['_id'], discount['code']),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}