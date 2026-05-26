import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/service_service.dart';

import '../../../helper/snackbar_helper.dart';

class ServiceManagement extends StatefulWidget {
  const ServiceManagement({super.key});

  @override
  State<ServiceManagement> createState() => _ServiceManagementState();
}

class _ServiceManagementState extends State<ServiceManagement> {
  final ServiceService _serviceService = ServiceService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _services = [];
  List<dynamic> _filteredServices = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final res = await _serviceService.listService();

      if (res['success'] == true) {
        _services = res['data'];
        _filteredServices = _services;
      }
    } catch (e) {
      SnackBarHelper.showError(
        context,
        'Không tải được danh sách dịch vụ',
      );
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _reloadServices() async {
    _searchController.clear();
    await _fetchServices();
  }

  void _onSearch() {
    final keyword = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredServices = _services.where((item) {
        return item['name']
            .toString()
            .toLowerCase()
            .contains(keyword);
      }).toList();
    });
  }

  void _confirmDelete(String serviceId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Xóa dịch vụ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Bạn có chắc muốn xóa dịch vụ này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteService(serviceId);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(String serviceId) async {
    try {
      final res = await _serviceService.deleteService(serviceId);

      if (res['success'] == true) {
        SnackBarHelper.showSuccess(context, 'Xóa thành công');
      } else {
        SnackBarHelper.showError(context, 'Xóa thất bại');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Có lỗi xảy ra');
    }

    _fetchServices();
  }

  Widget _buildTimePrices(List timePrices) {
    if (timePrices.isEmpty) {
      return const Text(
        'Chưa có gói thời gian',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: timePrices.map<Widget>((e) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: ColorConfig.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '${e['duration']} phút',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorConfig.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorConfig.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.spa_rounded,
              color: ColorConfig.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                _buildTimePrices(item['timePrices'] ?? []),
              ],
            ),
          ),

          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await context.push(
                  AdminRouterConfig.editService,
                  extra: {'item': item},
                );

                if (result == true && mounted) {
                  _fetchServices();
                }
              }

              if (value == 'delete') {
                _confirmDelete(item['_id']);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Chỉnh sửa'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Xóa',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.more_vert_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm dịch vụ...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 14),

          Text(
            'Không có dịch vụ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xfff6f7fb),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Quản lý dịch vụ',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _reloadServices,
            icon: const Icon(Icons.refresh_rounded),
          ),

          IconButton(
            onPressed: () async {
              final result = await context.push(
                AdminRouterConfig.addService,
              );

              if (result == true && mounted) {
                _fetchServices();
              }
            },
            icon: const Icon(Icons.add_rounded),
          ),

          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _buildSearchBox(),
            ),

            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : RefreshIndicator(
                onRefresh: _reloadServices,
                child: _filteredServices.isEmpty
                    ? ListView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height:
                      MediaQuery.of(context).size.height *
                          0.6,
                      child: _buildEmpty(),
                    ),
                  ],
                )
                    : ListView.builder(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: _filteredServices.length,
                  itemBuilder: (context, index) {
                    return _buildServiceItem(
                      _filteredServices[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}