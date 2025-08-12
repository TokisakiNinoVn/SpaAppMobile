import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spa_app/config/color_config.dart';

import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';
import 'package:spa_app/helper/full_screen_list_image.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/services/realtime_service.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/tinhthanh_service.dart';

import '../../quanly/widgets/list_technician_quanly_widget.dart';

class CityDetailScreen extends StatefulWidget {
  final String cityName;

  const CityDetailScreen({super.key, required this.cityName});

  @override
  State<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen> {
  final UserService userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _provinceSearchController = TextEditingController();

  late RealtimeService _realtimeService;
  final tinhThanhService = TinhThanhService();

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  List<dynamic> provinces = [];
  List<dynamic> filteredProvinces = [];
  List<String> allServices = [];
  List<String> selectedServices = [];

  bool isLoading = true;
  String searchQuery = '';
  String? statusFilter;
  bool showProvinceList = false;
  bool showStatusList = false;
  bool showServiceList = false;
  String? selectedProvince;

  bool isProvincesLoading = false;

  final List<Map<String, dynamic>> statusOptions = [
    {'value': null, 'label': 'Tất cả'},
    {'value': 'active', 'label': 'Hoạt động'},
    {'value': 'inactive', 'label': 'Không hoạt động'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _realtimeService = RealtimeService(
      context,
      onUserStatusUpdate: (data) {
        if (!mounted) return;
        setState(() {
          _handleRealtimeUserStatusUpdate(data);
        });
      },
    );
    _realtimeService.connect();
    _loadProvinces();

  }

  void _handleRealtimeUserStatusUpdate(Map<String, dynamic> data) {
    final String userId = data['userId'];
    final bool status = data['status'];

    final int index = users.indexWhere((user) => user['_id'] == userId);
    if (index != -1) {
      setState(() {
        users[index]['status'] = status ? 'active' : 'inactive';
        _applyFilters();
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await userService.getAllUserService();
      if (response['success']) {
        final allUsers = List<Map<String, dynamic>>.from(response['data']);

        final filteredUsers = allUsers.where((user) =>
        user['roles'] == 'ktv' && user['isAcceptHaveApprovalRequest'] == true && user['technician']?['province'] == widget.cityName
        ).toList();

        Set<String> serviceSet = {};
        for (var user in filteredUsers) {
          if (user['technician']?['services'] != null) {
            serviceSet.addAll((user['technician']['services'] as List).cast<String>());
          }
        }

        setState(() {
          users = filteredUsers;
          allServices = serviceSet.toList();
          _applyFilters();
        });
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    filteredUsers = users.where((user) {
      final matchesSearch = user['phone'].toString().contains(searchQuery) ||
          (user['technician']?['fullName'].toString() ?? '').toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus = statusFilter == null || user['status'] == statusFilter;
      final matchesProvince = selectedProvince == null || selectedProvince == 'Tất cả' || user['technician']?['province'] == selectedProvince;
      final matchesServices = selectedServices.isEmpty || (user['technician']?['services'] as List?)!.any((s) => selectedServices.contains(s)) ?? false;
      return matchesSearch && matchesStatus && matchesProvince && matchesServices;
    }).toList();

    filteredUsers.sort((a, b) {
      if (a['status'] == 'active' && b['status'] != 'active') return -1;
      if (a['status'] != 'active' && b['status'] == 'active') return 1;
      return 0;
    });
  }

  Future<void> _loadProvinces() async {
    setState(() => isProvincesLoading = true);
    try {
      final response = await tinhThanhService.getDetailsTinhThanhApiRoutesService();
      if (response['code'] == 200 || response['status'] == 'success') {
        setState(() {
          provinces = response['data'];
          filteredProvinces = List.from(provinces);
          filteredProvinces.insert(0, {'name': 'Tất cả'});
        });
      } else {
        SnackbarHelper.showError(context,'Không thể tải danh sách tỉnh thành');
      }
    } catch (e) {
      SnackbarHelper.showError(context,'Lỗi tải tỉnh thành: $e');
    } finally {
      setState(() => isProvincesLoading = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea( // ✅ tránh bị che bởi thanh trạng thái
        child: Stack(
          children: [
            Column(
              children: [
                _buildSearchSection(),
                Expanded(
                  child: _buildUserListSection(),
                ),
              ],
            ),
            if (showStatusList) _buildStatusSelectionWidget(),
            if (showServiceList) _buildServiceSelectionWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // ✅ giảm padding top & bottom
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo số điện thoại hoặc tên',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            color: statusFilter != null ? Colors.blue : Colors.grey,
            onPressed: () {
              setState(() {
                showStatusList = true;
                showServiceList = false;
              });
            },
            tooltip: 'Lọc theo trạng thái',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_center_focus),
            color: selectedServices.isNotEmpty ? Colors.blue : Colors.grey,
            onPressed: () {
              setState(() {
                showServiceList = true;
                showStatusList = false;
              });
            },
            tooltip: 'Lọc theo dịch vụ',
          ),
        ],
      ),
    );
  }


  Widget _buildStatusSelectionWidget() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Chọn trạng thái',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        showStatusList = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: statusOptions.length,
                itemBuilder: (context, index) {
                  final option = statusOptions[index];
                  return ListTile(
                    title: Text(option['label']),
                    onTap: () {
                      setState(() {
                        statusFilter = option['value'];
                        showStatusList = false;
                        _applyFilters();
                      });
                    },
                    trailing: statusFilter == option['value']
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelectionWidget() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Chọn dịch vụ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedServices.clear();
                        _applyFilters();
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showServiceList = false;
                        _applyFilters();
                      });
                    },
                    child: const Text('Apply'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        showServiceList = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allServices.length,
                itemBuilder: (context, index) {
                  final service = allServices[index];
                  final isSelected = selectedServices.contains(service);
                  return CheckboxListTile(
                    title: Text(service),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedServices.add(service);
                        } else {
                          selectedServices.remove(service);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListSection() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : filteredUsers.isEmpty
        ? const Center(child: Text('Không có người dùng nào phù hợp'))
        : Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 120 / 228,
        ),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final hasTechnician = user['technician'] != null;
          final technician = hasTechnician ? user['technician'] : null;
          final avatarUrl = hasTechnician && technician?['avatar']?['url'] != null
              ? technician!['avatar']['url'] ?? ''
              : null;
          return GestureDetector(
            onTap: () => _showUserDetails(user),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    child: avatarUrl != null
                        ? Image.network(
                      avatarUrl,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 50, color: Colors.grey),
                          ),
                    )
                        : Container(
                      height: 140,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (user['status'] == 'active') ...[
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            technician?['fullName'] ?? 'Không có tên',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${technician?['yearOfBirth'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: (technician?['services'] as List<dynamic>? ?? [])
                              .map((service) => Text(
                            service.toString(),
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ))
                              .toList(),
                        )
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

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserDetailWidget(user: user),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provinceSearchController.dispose();
    super.dispose();
  }
}