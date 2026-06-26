import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/helper/format_helper.dart';

class ManageDisplayTechnician extends StatefulWidget {
  const ManageDisplayTechnician({super.key});

  @override
  State<ManageDisplayTechnician> createState() =>
      _ManageDisplayTechnicianState();
}

class _ManageDisplayTechnicianState extends State<ManageDisplayTechnician> {
  final TechnicianService _technicianService = TechnicianService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _technicians = [];

  Map<String, bool> _displayMap = {};
  Map<String, bool> _originalDisplayMap = {};

  String _searchQuery = ''; // Query thực sự dùng để lọc
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    listViewTechnician();
    // KHÔNG thêm listener nữa → tránh lag khi gõ
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    for (final key in _displayMap.keys) {
      if (_displayMap[key] != _originalDisplayMap[key]) {
        return true;
      }
    }
    return false;
  }

  // Lọc theo _searchQuery (chỉ thay đổi khi bấm "Tìm")
  List<dynamic> get _filteredTechnicians {
    if (_searchQuery.isEmpty) return _technicians;

    return _technicians.where((t) {
      final name = (t['fullName'] ?? '').toString().toLowerCase();
      final phone = (t['userId']?['phone'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || phone.contains(_searchQuery);
    }).toList();
  }

  bool get _allSelected =>
      _displayMap.isNotEmpty && _displayMap.values.every((v) => v == true);

  void _toggleSelectAll() {
    final selectAll = !_allSelected;
    setState(() {
      for (final key in _displayMap.keys) {
        _displayMap[key] = selectAll;
      }
    });
  }

  // Hàm tìm kiếm CHÍNH
  void _performSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
    });
  }

  // Xóa tìm kiếm
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  Future<void> listViewTechnician() async {
    try {
      final response = await _technicianService.listViewTechnician();

      if (response['success'] == true && response['data'] != null) {
        final listTechnician = response['data'] as List<dynamic>;

        final displayMap = <String, bool>{};
        for (final technician in listTechnician) {
          displayMap[technician['_id']] = technician['isDisplay'] == true;
        }

        setState(() {
          _technicians = listTechnician;
          _displayMap = Map.from(displayMap);
          _originalDisplayMap = Map.from(displayMap);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = response['message'] ?? "Lỗi khi tải dữ liệu";
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Lỗi kết nối: $e";
      });
    }
  }

  Widget _buildAvatar(dynamic technician) {
    final avatarUrl = FormatHelper.formatNetworkImageUrl(
      technician['avatar']?['url'],
    );

    if (avatarUrl.toString().isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.person),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(avatarUrl, width: 80, height: 80, fit: BoxFit.cover),
    );
  }

  String _genderText(String gender) {
    switch (gender) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }

  IconData _genderIcon(String gender) {
    switch (gender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.person;
    }
  }

  Future<void> _updateDisplayTechnician() async {
    final changedTechnicians =
        _displayMap.entries
            .where((e) => _originalDisplayMap[e.key] != e.value)
            .map((e) => {"id": e.key, "isDisplay": e.value})
            .toList();

    try {
      final response = await _technicianService.changeDisplayTechnician({
        'technicians': changedTechnicians,
      });

      if (response['success'] == true) {
        setState(() {
          _originalDisplayMap = Map.from(_displayMap);
        });

        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            "Cập nhật trạng thái hiển thị thành công!",
          );
        }
      } else {
        setState(() {
          _displayMap = Map.from(_originalDisplayMap);
        });
      }
    } catch (e) {
      appLog("Lỗi update display technician: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
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
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Hiển thị KTV",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (!_loading && _error == null)
              GestureDetector(
                onTap: _toggleSelectAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _allSelected
                            ? Colors.red.shade50
                            : const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _allSelected
                              ? Colors.red.shade300
                              : const Color(0xFF6B8FFF),
                    ),
                  ),
                  child: Text(
                    _allSelected ? 'Bỏ chọn' : 'Chọn hết',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          _allSelected
                              ? Colors.red.shade600
                              : const Color(0xFF3D6FFF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
              : Column(
                children: [
                  // === Search Bar ===
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction:
                                TextInputAction
                                    .search, // Bấm Enter trên bàn phím = Tìm
                            onSubmitted: (_) => _performSearch(),
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên hoặc số điện thoại...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF7F8FA),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _performSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConfig.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Tìm",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 22,
                              color: Colors.grey,
                            ),
                            onPressed: _clearSearch,
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredTechnicians.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final technician = _filteredTechnicians[index];
                        final id = technician['_id']?.toString() ?? '';
                        final fullName =
                            technician['fullName'] ?? 'Chưa cập nhật';
                        final phone =
                            technician['userId']?['phone']?.toString() ?? '';
                        final gender = technician['gender']?.toString() ?? '';

                        return Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              _buildAvatar(technician),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(_genderIcon(gender), size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          _genderText(gender),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: _displayMap[id] ?? false,
                                onChanged: (value) {
                                  setState(
                                    () => _displayMap[id] = value ?? false,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  if (_hasChanges)
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConfig.primary,
                            ),
                            onPressed: _updateDisplayTechnician,
                            child: const Text(
                              "Cập nhật",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}
