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
        SnackBarHelper.showError(context, response['message'] ?? 'Không thể tải danh sách khuyến mãi');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      SnackBarHelper.showError(context, 'Đã xảy ra lỗi khi tải dữ liệu');
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
          SnackBarHelper.showSuccess(context, 'Xóa mã khuyến mãi thành công');
          fetchDiscounts(); // Refresh list
        } else {
          SnackBarHelper.showError(context, response['message'] ?? 'Xóa thất bại');
        }
      } catch (e) {
        SnackBarHelper.showError(context, 'Đã xảy ra lỗi khi xóa');
      }
    }
  }

  Future<void> toggleIsActive(Map<String, dynamic> discount) async {
    try {
      final response = await discountService.changeIsActiveDiscount(
          discount['_id'],
        {
        'isActive': !discount['isActive'],
      });

      if (response['success'] == true) {
        SnackBarHelper.showSuccess(
            context,
            discount['isActive'] ? 'Đã vô hiệu hóa mã' : 'Đã kích hoạt mã'
        );
        fetchDiscounts(); // Refresh list
      } else {
        SnackBarHelper.showError(context, response['message'] ?? 'Thay đổi trạng thái thất bại');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Đã xảy ra lỗi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý khuyến mãi"),
        actions: [
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
          // Search and Filter section
          _buildSearchAndFilter(),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng số: ${filteredDiscounts.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (selectedIsActive != null ||
                    selectedTypeDiscount != null ||
                    startDateFilter != null ||
                    endDateFilter != null)
                  TextButton(
                    onPressed: clearFilters,
                    child: const Text('Xóa bộ lọc'),
                  ),
              ],
            ),
          ),

          // Discount list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDiscounts.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo mã hoặc mô tả...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
                applyFilters();
              });
            },
          ),
          const SizedBox(height: 12),

          // Filter row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Trạng thái',
                options: const ['true', 'false'],
                selectedValue: selectedIsActive,
                onSelected: (value) {
                  setState(() {
                    selectedIsActive = value;
                    applyFilters();
                  });
                },
                labelBuilder: (value) => value == 'true' ? 'Đang hoạt động' : 'Vô hiệu hóa',
              ),
              _buildFilterChip(
                label: 'Loại giảm giá',
                options: const ['percentage', 'fixed'],
                selectedValue: selectedTypeDiscount,
                onSelected: (value) {
                  setState(() {
                    selectedTypeDiscount = value;
                    applyFilters();
                  });
                },
                labelBuilder: (value) => value == 'percentage' ? 'Phần trăm' : 'Cố định',
              ),
              _buildDateFilterChip(
                label: 'Từ ngày',
                selectedDate: startDateFilter,
                onSelect: (date) {
                  setState(() {
                    startDateFilter = date;
                    applyFilters();
                  });
                },
              ),
              _buildDateFilterChip(
                label: 'Đến ngày',
                selectedDate: endDateFilter,
                onSelect: (date) {
                  setState(() {
                    endDateFilter = date;
                    applyFilters();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onSelected,
    required String Function(String) labelBuilder,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selectedValue != null,
      onSelected: (selected) {
        if (selected) {
          // Show dialog to select option
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(label),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  return RadioListTile<String>(
                    title: Text(labelBuilder(option)),
                    value: option,
                    groupValue: selectedValue,
                    onChanged: (value) {
                      onSelected(value);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    onSelected(null);
                    Navigator.pop(context);
                  },
                  child: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
          );
        } else {
          onSelected(null);
        }
      },
      selectedColor: Colors.blue.shade100,
    );
  }

  Widget _buildDateFilterChip({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime?) onSelect,
  }) {
    return FilterChip(
      label: Text(selectedDate != null
          ? '$label: ${FormatHelper.formatDateTimeTypeDateTime(selectedDate)}'
          : label),
      selected: selectedDate != null,
      onSelected: (selected) async {
        if (selected) {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (date != null) {
            onSelect(date);
          }
        } else {
          onSelect(null);
        }
      },
      selectedColor: Colors.blue.shade100,
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          discount['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Hoạt động' : 'Vô hiệu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_offer, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        valueText,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.shopping_cart, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('Đơn tối thiểu: ${FormatHelper.formatPrice(discount['minOrderValue'])}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${FormatHelper.formatDate(discount['startAt'])} - ${FormatHelper.formatDate(discount['expiresAt'])}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('Đã dùng: ${discount['usedCount']}/${discount['maxUses']}'),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => context.push(AdminRouterConfig.editDiscount, extra: discount),
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Sửa'),
                ),
                // Toggle active/inactive button
                // TextButton.icon(
                //   onPressed: () => toggleIsActive(discount),
                //   icon: Icon(
                //     isActive ? Icons.block : Icons.check_circle,
                //     size: 20,
                //   ),
                //   label: Text(isActive ? 'Vô hiệu' : 'Kích hoạt'),
                //   style: TextButton.styleFrom(
                //     foregroundColor: isActive ? Colors.orange : Colors.green,
                //   ),
                // ),
                // Delete button
                TextButton.icon(
                  onPressed: () => deleteDiscount(discount['_id'], discount['code']),
                  icon: const Icon(Icons.delete, size: 20),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
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