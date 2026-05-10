import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';

import 'package:spa_app/screens/admin/widgets/user_detail.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/services/realtime_service.dart';
// import 'package:spa_app/helper/snackbar_helper.dart';
// import 'package:spa_app/services/tinhthanh_service.dart';
import 'package:spa_app/services/tinhthanh_service_v2.dart';
import 'package:spa_app/services/technician_service.dart';

class CityDetailScreen extends StatefulWidget {
  final String cityName;
  final int cityId;

  const CityDetailScreen({super.key, required this.cityName, required this.cityId});

  @override
  State<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen> {
  final UserService userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _provinceSearchController = TextEditingController();

  late RealtimeService _realtimeService;
  final tinhThanhService = TinhThanhService();
  final technicianService = TechnicianService();

  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> filteredTechnicians = [];
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
  bool showDistrictList = false;
  String? selectedProvince;
  String? selectedDistrict;

  bool isProvincesLoading = false;
  List<Map<String, dynamic>> districts = [];

  final List<Map<String, dynamic>> statusOptions = [
    {'value': null, 'label': 'Tất cả'},
    {'value': 'active', 'label': 'Hoạt động'},
    {'value': 'inactive', 'label': 'Không hoạt động'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
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
    _loadDistricts();
  }

  void _handleRealtimeUserStatusUpdate(Map<String, dynamic> data) {
    final String userId = data['userId'];
    final bool status = data['status'];

    final int index = technicians.indexWhere((tech) => tech['userId']?['_id'] == userId);
    if (index != -1) {
      setState(() {
        technicians[index]['userId']['status'] = status ? 'active' : 'inactive';
        _applyFilters();
      });
    }
  }

  Future<void> _loadTechnicians() async {
    setState(() => isLoading = true);
    try {
      final response = await technicianService.filterTechnicianByIdProvince(widget.cityId);
      // print("response: $response");
      if (response['success']) {
        final techniciansData = List<Map<String, dynamic>>.from(response['data']);

        // Extract all unique services from technicians
        Set<String> serviceSet = {};
        for (var tech in techniciansData) {
          if (tech['services'] != null) {
            serviceSet.addAll((tech['services'] as List).cast<String>());
          }
        }

        setState(() {
          technicians = techniciansData;
          allServices = serviceSet.toList();
          _applyFilters();
        });
      }
    } catch (e) {
      print('Error loading technicians: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadDistricts() async {
    try {
      districts = await tinhThanhService.getHuyenByTinhV2(widget.cityId);
      // debugPrint("List huyen: ${districts}");
    } catch (e) {
      print('Error loading districts: $e');
      districts = [];
    }
  }

  void _applyFilters() {
    filteredTechnicians = technicians.where((tech) {
      final userPhone = tech['userId']?['phone']?.toString() ?? '';
      final technicianName = tech['fullName']?.toString() ?? '';

      final matchesSearch = userPhone.contains(searchQuery) ||
          technicianName.toLowerCase().contains(searchQuery.toLowerCase());

      final userStatus = tech['userId']?['status'] ?? 'inactive';
      final matchesStatus = statusFilter == null || userStatus == statusFilter;

      final matchesDistrict = selectedDistrict == null ||
          selectedDistrict == 'Tất cả' ||
          (tech['districts'] as List?)?.contains(selectedDistrict) == true;

      final matchesServices = selectedServices.isEmpty ||
          (tech['services'] as List?)?.any((s) => selectedServices.contains(s)) == true;

      return matchesSearch && matchesStatus && matchesDistrict && matchesServices;
    }).toList();

    filteredTechnicians.sort((a, b) {
      final statusA = a['userId']?['status'] ?? 'inactive';
      final statusB = b['userId']?['status'] ?? 'inactive';

      if (statusA == 'active' && statusB != 'active') return -1;
      if (statusA != 'active' && statusB == 'active') return 1;
      return 0;
    });
  }

  void _closeAllFilterPanels() {
    setState(() {
      showStatusList = false;
      showServiceList = false;
      showDistrictList = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (showStatusList || showServiceList || showDistrictList)
              GestureDetector(
                onTap: _closeAllFilterPanels,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.cityName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.pin_drop_rounded),
                          color: selectedDistrict != null ? Colors.blue : Colors.grey,
                          onPressed: () {
                            setState(() {
                              showDistrictList = true;
                              showStatusList = false;
                              showServiceList = false;
                            });
                          },
                          tooltip: 'Lọc theo quận/huyện',
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_alt_outlined),
                          color: statusFilter != null ? Colors.blue : Colors.grey,
                          onPressed: () {
                            setState(() {
                              showStatusList = true;
                              showServiceList = false;
                              showDistrictList = false;
                            });
                          },
                          tooltip: 'Lọc theo trạng thái',
                        ),
                        // IconButton(
                        //   icon: const Icon(Icons.library_add_check_sharp),
                        //   color: selectedServices.isNotEmpty ? Colors.blue : Colors.grey,
                        //   onPressed: () {
                        //     setState(() {
                        //       showServiceList = true;
                        //       showStatusList = false;
                        //       showDistrictList = false;
                        //     });
                        //   },
                        //   tooltip: 'Lọc theo dịch vụ',
                        // ),
                      ],
                    ),
                  ],
                ),

                _buildSearchSection(),

                Expanded(
                  child: _buildTechnicianListSection(),
                ),
              ],
            ),

            // Filter panels
            if (showStatusList) _buildStatusSelectionWidget(),
            if (showServiceList) _buildServiceSelectionWidget(),
            if (showDistrictList) _buildDistrictSelectionWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo số điện thoại hoặc tên.',
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
                    onPressed: _closeAllFilterPanels,
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
                        _closeAllFilterPanels();
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
                    onPressed: _closeAllFilterPanels,
                    child: const Text('Apply'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _closeAllFilterPanels,
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

  Widget _buildDistrictSelectionWidget() {
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
                    'Chọn quận/huyện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedDistrict = null;
                        _applyFilters();
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _closeAllFilterPanels,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: districts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      title: const Text('Tất cả'),
                      onTap: () {
                        setState(() {
                          selectedDistrict = null;
                          _closeAllFilterPanels();
                          _applyFilters();
                        });
                      },
                      trailing: selectedDistrict == null
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                    );
                  }

                  final district = districts[index - 1];
                  final districtName = district['name'] ?? '';
                  final isSelected = selectedDistrict == districtName;

                  return ListTile(
                    title: Text(districtName),
                    onTap: () {
                      setState(() {
                        selectedDistrict = districtName;
                        _closeAllFilterPanels();
                        _applyFilters();
                      });
                    },
                    trailing: isSelected
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

  Widget _buildTechnicianListSection() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : filteredTechnicians.isEmpty
        ? const Center(child: Text('Không có kỹ thuật viên nào phù hợp'))
        : Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 120 / 150,
        ),
        itemCount: filteredTechnicians.length,
        itemBuilder: (context, index) {
          final technician = filteredTechnicians[index];
          final user = technician['userId'] ?? {};
          final avatarUrl = technician['avatar']?['url'];
          final status = user['status'] ?? 'inactive';
          final fullName = technician['fullName'] ?? 'Không có tên';
          final yearOfBirth = technician['yearOfBirth']?.toString() ?? 'Chưa có';
          final services = technician['services'] as List<dynamic>? ?? [];
          final phone = user['phone'] ?? '';

          return GestureDetector(
            onTap: () => _showTechnicianDetails(technician),
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
                      FormatHelper.formatNetworkImageUrl(avatarUrl),
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 40, color: Colors.grey),
                          ),
                    )
                        : Container(
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (status == 'active') ...[
                          Container(
                            width: 11,
                            height: 11,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],

                        Flexible(
                          child: SizedBox(
                            height: 20,
                            child: fullName.length > 20
                                ? Marquee(
                              text: fullName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              blankSpace: 100,
                              velocity: 30,
                              startAfter: const Duration(seconds: 1),
                              pauseAfterRound: const Duration(seconds: 1),
                              numberOfRounds: 1,
                            )
                                : Text(
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Flexible(
                        //   child: SizedBox(
                        //     height: 20,
                        //     child: Marquee(
                        //       text: fullName,
                        //       style: const TextStyle(
                        //         fontSize: 14,
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //       scrollAxis: Axis.horizontal,
                        //       crossAxisAlignment: CrossAxisAlignment.center,
                        //       blankSpace: 50.0,
                        //       velocity: 30.0,
                        //       startAfter: const Duration(seconds: 1),
                        //       pauseAfterRound: const Duration(seconds: 1),
                        //       showFadingOnlyWhenScrolling: false,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Năm sinh: $yearOfBirth',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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

  void _showTechnicianDetails(Map<String, dynamic> technician) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserDetailWidgetAdmin(user: technician),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provinceSearchController.dispose();
    super.dispose();
  }
}