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

  bool isLoading = true;
  String searchQuery = '';
  String? statusFilter;
  bool showProvinceList = false;
  bool showStatusList = false;
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
      context: context,
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

        setState(() {
          users = filteredUsers;
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
      return matchesSearch && matchesStatus && matchesProvince;
    }).toList();
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

  void _filterProvinces(String query) {
    setState(() {
      filteredProvinces = provinces.where((province) {
        return province['name'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
      filteredProvinces.insert(0, {'name': 'Tất cả'});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchSection(),
              Expanded(
                child: _buildUserListSection(),
              ),
            ],
          ),
          // if (showProvinceList) _buildProvinceSelectionWidget(),
          if (showStatusList) _buildStatusSelectionWidget(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
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
                    showProvinceList = false;
                  });
                },
                tooltip: 'Lọc theo trạng thái',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // GestureDetector(
          //   onTap: () {
          //     setState(() {
          //       showProvinceList = true;
          //       showStatusList = false;
          //     });
          //   },
          //   child: AbsorbPointer(
          //     child: TextFormField(
          //       controller: TextEditingController(text: selectedProvince ?? ''),
          //       decoration: InputDecoration(
          //         hintText: 'Chọn tỉnh thành',
          //         prefixIcon: const Icon(Icons.location_on),
          //         suffixIcon: selectedProvince != null
          //             ? IconButton(
          //           icon: const Icon(Icons.clear),
          //           onPressed: () {
          //             setState(() {
          //               selectedProvince = null;
          //               _applyFilters();
          //             });
          //           },
          //         )
          //             : null,
          //         filled: true,
          //         fillColor: Colors.grey.shade100,
          //         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          //         border: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(24),
          //           borderSide: BorderSide.none,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget _buildProvinceSelectionWidget() {
  //   return Positioned(
  //     bottom: 0,
  //     left: 0,
  //     right: 0,
  //     child: Container(
  //       height: MediaQuery.of(context).size.height * 0.5,
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.2),
  //             blurRadius: 8,
  //             offset: const Offset(0, -2),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  //             child: Row(
  //               children: [
  //                 const Text(
  //                   'Chọn tỉnh thành',
  //                   style: TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const Spacer(),
  //                 IconButton(
  //                   icon: const Icon(Icons.close),
  //                   onPressed: () {
  //                     setState(() {
  //                       showProvinceList = false;
  //                     });
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
  //             child: TextField(
  //               controller: _provinceSearchController,
  //               decoration: InputDecoration(
  //                 hintText: 'Tìm kiếm tỉnh thành',
  //                 prefixIcon: const Icon(Icons.search),
  //                 suffixIcon: _provinceSearchController.text.isNotEmpty
  //                     ? IconButton(
  //                   icon: const Icon(Icons.clear),
  //                   onPressed: () {
  //                     _provinceSearchController.clear();
  //                     _filterProvinces('');
  //                   },
  //                 )
  //                     : null,
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(24),
  //                 ),
  //               ),
  //               onChanged: _filterProvinces,
  //             ),
  //           ),
  //           Expanded(
  //             child: ListView.builder(
  //               itemCount: filteredProvinces.length,
  //               itemBuilder: (context, index) {
  //                 final province = filteredProvinces[index];
  //                 return ListTile(
  //                   title: Text(province['name']),
  //                   onTap: () {
  //                     setState(() {
  //                       selectedProvince = province['name'] == 'Tất cả' ? null : province['name'];
  //                       showProvinceList = false;
  //                       _applyFilters();
  //                     });
  //                   },
  //                   trailing: selectedProvince == province['name'] ||
  //                       (selectedProvince == null && province['name'] == 'Tất cả')
  //                       ? Icon(Icons.check, color: ColorConfig.textSuccess)
  //                       : null,
  //                 );
  //               },
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

  Widget _buildUserListSection() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : filteredUsers.isEmpty
        ? const Center(child: Text('Không có người dùng nào phù hợp'))
        : Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.builder(
        // shrinkWrap: true,
        // physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 160 / 190,
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: avatarUrl != null
                        ? Image.network(
                      avatarUrl,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            height: 160,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 50, color: Colors.grey),
                          ),
                    )
                        : Container(
                      height: 160,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              fontSize: 15,
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
                  // const SizedBox(height: 12),
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

class UserDetailWidget extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bool hasTechnician = user['technician'] != null;
    final technician = hasTechnician ? user['technician'] : null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chi tiết tài khoản',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        final imageUrl = technician?['avatar']?['url'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => FullScreenSingleImageViewer(
                                imageUrl: imageUrl),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasTechnician && technician?['avatar'] != null
                            ? Image.network(
                          technician!['avatar']['url'] ?? '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      user['role'] == 'ktv' ? (user['fullName'] ?? 'Không có tên') : '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  _buildCopyableDetailRow(context, 'Số điện thoại', user['phone']),
                  _buildCopyableDetailRow(context, 'Mật khẩu', user['password']),
                  _buildDetailRow('Trạng thái', user['status'] == 'active' ? 'Hoạt động' : 'Không hoạt động'),
                  _buildDetailRow(
                    'Lần đăng nhập cuối',
                    user['lastLogin'] != null ? FormatHelper.formatDateTime(user['lastLogin']) : 'Không có',
                  ),
                  if (hasTechnician) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Thông tin Kỹ thuật viên - ori',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildDetailRow('Tên đầy đủ', technician?['fullName']),
                    _buildDetailRow('Tỉnh/Thành phố', technician?['province']),
                    _buildDetailRow('Quận/Huyện', technician?['district']),
                    _buildDetailRow('Phường/Xã', technician?['commune']),
                    _buildDetailRow('Địa chỉ', technician?['address']),
                    _buildDetailRow('Kinh nghiệm', technician?['experience']),
                    _buildDetailRow('Giới thiệu', technician?['bio']),
                    _buildDetailRow('Phê duyệt', technician?['isAcceptHaveApprovalRequest'] == true ? 'Đã được phê duyệt' : 'Chưa được phê duyệt'),
                    if (technician?['images'] != null && (technician!['images'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Hình ảnh',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (technician['images'] as List).length,
                          itemBuilder: (context, index) {
                            final image = (technician['images'] as List)[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => _showFullScreenImages(context, technician['images'], index),
                                child: Image.network(
                                  image['url'] ?? '',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImages(BuildContext context, List<dynamic> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => FullScreenImageViewer(
        images: images,
        initialIndex: initialIndex,
        formatImageUrl: FormatHelper.formatImageUrl,
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableDetailRow(BuildContext context, String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          tooltip: 'Copy $label',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Đã copy $label")),
            );
          },
        ),
      ],
    );
  }
}
