// lib/widgets/district_picker_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';

/// Model cho quận/huyện
class District {
  final int id;
  final String name;
  final Map<String, dynamic>? rawData;

  District({required this.id, required this.name, this.rawData});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      name: json['name'] as String,
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is District && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Hiển thị bottom sheet chọn nhiều quận/huyện
/// Trả về danh sách các District đã chọn, hoặc null nếu hủy.
Future<List<District>?> showDistrictPickerBottomSheet({
  required BuildContext context,
  required List<District> districts,
  List<District>? initialSelected,
  String title = 'Chọn quận/huyện làm việc',
  String searchHint = 'Tìm kiếm quận/huyện',
}) async {
  return showModalBottomSheet<List<District>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _DistrictPickerSheetContent(
        districts: districts,
        initialSelected: initialSelected ?? [],
        title: title,
        searchHint: searchHint,
      ),
    ),
  );
}

class _DistrictPickerSheetContent extends StatefulWidget {
  final List<District> districts;
  final List<District> initialSelected;
  final String title;
  final String searchHint;

  const _DistrictPickerSheetContent({
    required this.districts,
    required this.initialSelected,
    required this.title,
    required this.searchHint,
  });

  @override
  State<_DistrictPickerSheetContent> createState() =>
      _DistrictPickerSheetContentState();
}

class _DistrictPickerSheetContentState
    extends State<_DistrictPickerSheetContent> {
  late List<District> _selected;
  final TextEditingController _searchController = TextEditingController();
  List<District> _filteredDistricts = [];

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _filteredDistricts = widget.districts;
    _searchController.addListener(_filterDistricts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDistricts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterDistricts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDistricts = widget.districts.where((d) {
        return d.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleSelection(District district) {
    setState(() {
      if (_selected.contains(district)) {
        _selected.remove(district);
      } else {
        _selected.add(district);
      }
    });
  }

  void _confirm() {
    Navigator.pop(context, _selected);
  }

  Widget _buildSheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: widget.searchHint,
        prefixIcon: const Icon(Icons.search, color: Color(0xFF999999), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _confirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConfig.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          elevation: 0,
        ),
        child: const Text('Xác nhận'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildSheetHandle(),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredDistricts.length,
              itemBuilder: (context, index) {
                final district = _filteredDistricts[index];
                final isSelected = _selected.contains(district);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    district.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF666666),
                    ),
                  ),
                  value: isSelected,
                  activeColor: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  onChanged: (_) => _toggleSelection(district),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildConfirmButton(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}