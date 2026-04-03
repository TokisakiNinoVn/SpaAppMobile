import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/services/service_service.dart';

class ListTechnicianScreen extends StatefulWidget {
  const ListTechnicianScreen({super.key});

  @override
  State<ListTechnicianScreen> createState() => _ListTechnicianScreenState();
}

class _ListTechnicianScreenState extends State<ListTechnicianScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final ServiceService _serviceService = ServiceService();
  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> filteredTechnicians = [];
  List<Map<String, dynamic>> services = [];

  // Filter states
  String? selectedGender;
  String? selectedServiceId;
  String searchQuery = '';

  // Filter panel visibility
  bool showFilterPanel = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadListService();
    await _loadListTechnician();
  }

  Future<void> _loadListService() async {
    try {
      final response = await _serviceService.listBaseService();
      if (response['success'] == true || response['success'] == true) {
        setState(() {
          services = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
      } else {
        print("============== Else ==================");
      }
    } catch (e) {
      print('Error loading services: $e');
    }
  }

  Future<void> _loadListTechnician() async {
    try {
      final response = await _technicianService.getListTechnicianForCustomer();
      if (response['success'] == true  || response['success'] == true) {

        setState(() {
          technicians = List<Map<String, dynamic>>.from(response['data'] ?? []);
          filteredTechnicians = List.from(technicians);
        });
      } else {
        print("============== Else ==================");
      }
    } catch (e) {
      print('Error loading technicians: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      filteredTechnicians = technicians.where((tech) {
        // Filter by gender
        if (selectedGender != null && selectedGender!.isNotEmpty) {
          if (tech['gender'] != selectedGender) {
            return false;
          }
        }

        // Filter by service
        if (selectedServiceId != null && selectedServiceId!.isNotEmpty) {
          final techServices = List<Map<String, dynamic>>.from(tech['service'] ?? []);
          final hasService = techServices.any((service) => service['_id'] == selectedServiceId);
          if (!hasService) {
            return false;
          }
        }

        // Filter by search query
        if (searchQuery.isNotEmpty) {
          final fullName = tech['fullName']?.toString().toLowerCase() ?? '';
          final province = tech['province']?.toString().toLowerCase() ?? '';
          final districts = List<String>.from(tech['districts'] ?? [])
              .map((d) => d.toLowerCase())
              .join(' ');

          return fullName.contains(searchQuery.toLowerCase()) ||
              province.contains(searchQuery.toLowerCase()) ||
              districts.contains(searchQuery.toLowerCase());
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      selectedGender = null;
      selectedServiceId = null;
      searchQuery = '';
      filteredTechnicians = List.from(technicians);
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      showFilterPanel = !showFilterPanel;
    });
  }

  // void _showGenderFilterSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return Container(
  //         padding: const EdgeInsets.all(20),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Center(
  //               child: Container(
  //                 width: 40,
  //                 height: 4,
  //                 margin: const EdgeInsets.only(bottom: 16),
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFFE8D8C3),
  //                   borderRadius: BorderRadius.circular(2),
  //                 ),
  //               ),
  //             ),
  //             Text(
  //               'Chọn giới tính',
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w600,
  //                 color: const Color(0xFF5D4037),
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             ...['male', 'female', 'other'].map((gender) {
  //               String genderText = '';
  //               switch (gender) {
  //                 case 'male':
  //                   genderText = 'Nam';
  //                   break;
  //                 case 'female':
  //                   genderText = 'Nữ';
  //                   break;
  //                 case 'other':
  //                   genderText = 'Khác';
  //                   break;
  //               }
  //
  //               return ListTile(
  //                 contentPadding: EdgeInsets.zero,
  //                 leading: Radio<String>(
  //                   value: gender,
  //                   groupValue: selectedGender,
  //                   onChanged: (value) {
  //                     setState(() {
  //                       selectedGender = value;
  //                     });
  //                     Navigator.pop(context);
  //                     _applyFilters();
  //                   },
  //                   activeColor: const Color(0xFFD4A574),
  //                 ),
  //                 title: Text(
  //                   genderText,
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     color: const Color(0xFF5D4037),
  //                   ),
  //                 ),
  //                 onTap: () {
  //                   setState(() {
  //                     selectedGender = gender;
  //                   });
  //                   Navigator.pop(context);
  //                   _applyFilters();
  //                 },
  //               );
  //             }).toList(),
  //             const SizedBox(height: 8),
  //             if (selectedGender != null)
  //               TextButton(
  //                 onPressed: () {
  //                   setState(() {
  //                     selectedGender = null;
  //                   });
  //                   Navigator.pop(context);
  //                   _applyFilters();
  //                 },
  //                 child: Text(
  //                   'Bỏ chọn',
  //                   style: TextStyle(
  //                     color: const Color(0xFFB08D57),
  //                     fontSize: 16,
  //                   ),
  //                 ),
  //               ),
  //             const SizedBox(height: 20),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    const Color spaPrimaryColor = Color(0xFFD4A574);
    const Color spaSecondaryColor = Color(0xFFB08D57);
    const Color spaBackgroundColor = Color(0xFFF9F5F0);
    const Color spaTextColor = Color(0xFF5D4037);
    const Color spaDividerColor = Color(0xFFE8D8C3);
    const Color spaLightTextColor = Color(0xFF8D6E63);

    return Scaffold(
      backgroundColor: spaBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: spaBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: spaDividerColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: spaTextColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: spaDividerColor, width: 1),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm kỹ thuật viên...",
                    hintStyle: TextStyle(color: spaTextColor.withOpacity(0.6)),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: spaSecondaryColor),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.filter_list, color: spaSecondaryColor),
              tooltip: 'Lọc',
              onPressed: _toggleFilterPanel,
            ),
            IconButton(
              icon: Icon(Icons.favorite, color: spaSecondaryColor),
              tooltip: 'Yêu thích',
              onPressed: () {
                context.go('/favorites');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Active filters display
          if (selectedGender != null || selectedServiceId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.filter_alt, color: spaSecondaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (selectedGender != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: spaDividerColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    selectedGender == 'male' ? 'Nam' :
                                    selectedGender == 'female' ? 'Nữ' : 'Khác',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: spaTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedGender = null;
                                      });
                                      _applyFilters();
                                    },
                                    child: Icon(Icons.close, size: 16, color: spaTextColor),
                                  ),
                                ],
                              ),
                            ),
                          if (selectedServiceId != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: spaDividerColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    services.firstWhere(
                                          (s) => s['_id'] == selectedServiceId,
                                      orElse: () => {'name': 'Dịch vụ'},
                                    )['name'] ?? 'Dịch vụ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: spaTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedServiceId = null;
                                      });
                                      _applyFilters();
                                    },
                                    child: Icon(Icons.close, size: 16, color: spaTextColor),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedGender != null || selectedServiceId != null)
                    TextButton(
                      onPressed: _clearFilters,
                      child: Text(
                        'Xóa bộ lọc',
                        style: TextStyle(
                          color: spaSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Filter panel
          if (showFilterPanel)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bộ lọc',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: spaTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gender filter
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giới tính',
                        style: TextStyle(
                          fontSize: 16,
                          color: spaLightTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: Text('Nam'),
                            selected: selectedGender == 'male',
                            onSelected: (selected) {
                              setState(() {
                                selectedGender = selected ? 'male' : null;
                              });
                            },
                            selectedColor: spaPrimaryColor,
                            backgroundColor: spaDividerColor,
                            labelStyle: TextStyle(
                              color: selectedGender == 'male' ? Colors.white : spaTextColor,
                            ),
                          ),
                          FilterChip(
                            label: Text('Nữ'),
                            selected: selectedGender == 'female',
                            onSelected: (selected) {
                              setState(() {
                                selectedGender = selected ? 'female' : null;
                              });
                            },
                            selectedColor: spaPrimaryColor,
                            backgroundColor: spaDividerColor,
                            labelStyle: TextStyle(
                              color: selectedGender == 'female' ? Colors.white : spaTextColor,
                            ),
                          ),
                          FilterChip(
                            label: Text('Khác'),
                            selected: selectedGender == 'other',
                            onSelected: (selected) {
                              setState(() {
                                selectedGender = selected ? 'other' : null;
                              });
                            },
                            selectedColor: spaPrimaryColor,
                            backgroundColor: spaDividerColor,
                            labelStyle: TextStyle(
                              color: selectedGender == 'other' ? Colors.white : spaTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Service filter
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dịch vụ',
                        style: TextStyle(
                          fontSize: 16,
                          color: spaLightTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (services.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: selectedServiceId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: spaDividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: spaDividerColor),
                            ),
                            filled: true,
                            fillColor: spaBackgroundColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Tất cả dịch vụ',
                                style: TextStyle(color: spaLightTextColor),
                              ),
                            ),
                            ...services.map((service) {
                              return DropdownMenuItem<String>(
                                value: service['_id'] as String,
                                child: Text(
                                  service['name'] ?? 'Không tên',
                                  style: TextStyle(color: spaTextColor),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedServiceId = value;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: spaSecondaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Xóa bộ lọc',
                            style: TextStyle(
                              color: spaSecondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            _toggleFilterPanel();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: spaPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Áp dụng',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: spaBackgroundColor,
            child: Row(
              children: [
                Text(
                  'Kết quả: ',
                  style: TextStyle(
                    color: spaLightTextColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${filteredTechnicians.length} kỹ thuật viên',
                  style: TextStyle(
                    color: spaTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Technician list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
              itemCount: filteredTechnicians.length,
              itemBuilder: (context, index) {
                final tech = filteredTechnicians[index];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: spaDividerColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: spaDividerColor, width: 0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: tech['avatar'] != null && tech['avatar']['url'] != null
                              ? Image.network(
                            tech['avatar']['url'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: spaDividerColor,
                                child: Icon(
                                  Icons.person,
                                  color: spaLightTextColor,
                                  size: 40,
                                ),
                              );
                            },
                          )
                              : Container(
                            color: spaDividerColor,
                            child: Icon(
                              Icons.person,
                              color: spaLightTextColor,
                              size: 40,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Technician info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FormatHelper.formatNameTechnician(tech['fullName'] ?? 'Không tên'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: spaTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: spaLightTextColor, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    tech['province'] ?? 'Chưa cập nhật',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: spaLightTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, color: spaSecondaryColor, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  tech['rate']?.toString() ?? '0.0',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: spaSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Book button
                      ElevatedButton(
                        onPressed: () {
                          context.go(
                            '/home-customer/list-technician/detail-technician',
                            extra: tech['_id'],
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: spaPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          "Đặt",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}