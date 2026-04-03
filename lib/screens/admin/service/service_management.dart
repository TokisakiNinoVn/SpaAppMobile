import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/service_service.dart';
import '../../../helper/snackbar_helper.dart';
import 'package:spa_app/services/service_service.dart';

class ServiceTab extends StatefulWidget {
  const ServiceTab({super.key});

  @override
  State<ServiceTab> createState() => _ServiceTabState();
}

class _ServiceTabState extends State<ServiceTab> {
  
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

  void _reloadServices() {
    _searchController.clear();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _loading = true);

    try {
      final res = await _serviceService.listService();
      if (res['success'] == true) {
        _services = res['data'];
        _filteredServices = _services;
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Không tải được danh sách dịch vụ');
    }

    setState(() => _loading = false);
  }

  void _onSearch() {
    final keyword = _searchController.text.toLowerCase();

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
        title: const Text('Xóa dịch vụ'),
        content: const Text('Bạn có chắc muốn xóa dịch vụ này không?'),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteService(serviceId);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(String serviceId) async {
    try {
      final res = await _serviceService.deleteService(serviceId);
      if (res['success'] == true) {
        SnackbarHelper.showSuccess(context, 'Xóa thành công');
      } else {
        SnackbarHelper.showError(context, 'Xóa thất bại');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Có lỗi xảy ra');
    }
    _fetchServices();
  }

  Widget _buildTimePrices(List timePrices) {
    if (timePrices.isEmpty) {
      return const Text(
        'Chưa có gói thời gian',
        style: TextStyle(color: Colors.grey),
      );
    }

    final durations = timePrices
        .map((e) => '${e['duration']}')
        .join(' / ');

    return Text(
      durations,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildServiceItem(dynamic item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _buildTimePrices(item['timePrices'] ?? []),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              context.push(
                '/home-admin/service/edit',
                extra: {'item': item},
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(item['_id']),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // SEARCH
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên dịch vụ...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // RELOAD
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.green),
                tooltip: 'Tải lại danh sách',
                onPressed: _loading ? null : _reloadServices,
              ),

              const SizedBox(width: 2),

              // ADD
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                tooltip: 'Thêm dịch vụ',
                onPressed: () {
                  context.go('/home-admin/service/add');
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // LIST
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredServices.isEmpty
                ? const Center(child: Text('Không có dịch vụ'))
                : ListView.builder(
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                return _buildServiceItem(
                    _filteredServices[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
