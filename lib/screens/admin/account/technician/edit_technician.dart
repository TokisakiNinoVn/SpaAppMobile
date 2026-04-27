import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';

import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/tinhthanh_service_v2.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/service_service.dart';

final ServiceService _serviceService = ServiceService();

class EditTechnicianScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditTechnicianScreen({super.key, required this.data});

  @override
  State<EditTechnicianScreen> createState() => _EditTechnicianScreenState();
}

class _EditTechnicianScreenState extends State<EditTechnicianScreen> {
  final fullnameController = TextEditingController();
  final addressController = TextEditingController();
  final bioController = TextEditingController();
  final technicianService = TechnicianService();
  final tinhThanhService = TinhThanhService();

  bool isLoading = false;
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> filteredDistricts = [];
  List<dynamic> filteredProvinces = [];
  List<dynamic> filteredServices = [];
  List<String> _existingServiceIds = [];

  dynamic selectedProvince;
  List<dynamic> selectedDistricts = [];
  String? experience;
  String? gender;
  String selectedGender = 'female';

  List<Map<String, dynamic>> images = [];
  Map<String, dynamic>? avatarImage;
  List<String> services = [];
  List<dynamic> selectedServiceIds = [];
  List<dynamic>? allServices = [];

  final experiences = ['1 năm', '2 năm', '3 năm', '4 năm', '5 năm', '6 năm', '7 năm'];
  final genders = ['Nam', 'Nữ', 'Khác'];
  int? yearOfBirth;

  bool isProvincesLoading = false;
  bool isDistrictsLoading = false;

  final _districtSearchController = TextEditingController();
  final _serviceSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadProvinces();
    _loadAllServices();
  }

  void _initializeData() {
    final technicianData = widget.data['technician'];
    // appLog("$technicianData");

    fullnameController.text = technicianData['fullName'] ?? '';
    addressController.text = technicianData['address'] ?? '';
    // bioController.text = technicianData['bio'] ?? '';
    experience = technicianData['experience'] ?? '3 năm';
    gender = technicianData['gender'] ?? 'Nam';
    yearOfBirth = technicianData['yearOfBirth'];
    services = List<String>.from(technicianData['services'] ?? []);

    if (technicianData['avatar'] != null) {
      avatarImage = {
        '_id': technicianData['avatar']['_id'],
        'url': technicianData['avatar']['url'],
        'uploadedAt': technicianData['avatar']['uploadedAt'],
      };
    }

    final List<String> existingServiceIds = List<String>.from(technicianData['serviceIds'] ?? []);
    _existingServiceIds = existingServiceIds;

    if (technicianData['images'] != null && technicianData['images'].isNotEmpty) {
      images = List<Map<String, dynamic>>.from(
        technicianData['images'].map(
              (img) => {
            '_id': img['_id'],
            'url': img['url'],
            'uploadedAt': img['uploadedAt'],
          },
        ),
      );
    }
  }

  Future<void> _loadAllServices() async {
    try {
      final response = await _serviceService.listService();
      setState(() {
        allServices = response['data'];
        filteredServices = allServices ?? [];

        // Khớp các service ID cũ với object service từ API
        if (_existingServiceIds.isNotEmpty && allServices != null) {
          selectedServiceIds = allServices!.where((service) {
            return _existingServiceIds.contains(service['_id']);
          }).toList();
        }
      });
    } catch (e) {
      print("Error loading services: $e");
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => isProvincesLoading = true);
    try {
      final listTinhThanh = await tinhThanhService.getTinhThanh();
      if (listTinhThanh.isEmpty) {
        SnackBarHelper.showError(context, 'Không thể tải danh sách tỉnh thành');
      } else {
        setState(() {
          provinces = listTinhThanh;
          filteredProvinces = provinces;
          if (widget.data['technician']['province'] != null) {
            selectedProvince = provinces.firstWhereOrNull(
                    (prov) => prov['name'] == widget.data['technician']['province']
            );
            if (selectedProvince != null) {
              _loadDistricts(selectedProvince['id']);
            }
          }
        });
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi tải tỉnh thành: $e');
    } finally {
      setState(() => isProvincesLoading = false);
    }
  }

  Future<void> _loadDistricts(int idProvince) async {
    setState(() => isDistrictsLoading = true);
    try {
      final listQuanHuyen = await tinhThanhService.getHuyenByTinh(idProvince);
      if (listQuanHuyen.isEmpty) {
        SnackBarHelper.showError(context, 'Không thể tải danh sách huyện');
      } else {
        setState(() {
          districts = listQuanHuyen;
          filteredDistricts = districts;
          if (widget.data['technician']['districts'] != null) {
            selectedDistricts = districts
                .where(
                  (district) => widget.data['technician']['districts']
                  .contains(district['name']),
            )
                .toList();
          }
        });
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi tải huyện: $e');
    } finally {
      setState(() => isDistrictsLoading = false);
    }
  }

  Future<void> handleUpdateTechnician() async {
    final fullname = fullnameController.text.trim();
    final address = addressController.text.trim();
    final bio = bioController.text.trim();

    if (fullname.isEmpty) {
      _showSnack('Vui lòng nhập họ tên');
      return;
    }
    if (address.isEmpty) {
      _showSnack('Vui lòng nhập địa chỉ cụ thể');
      return;
    }
    if (selectedProvince == null) {
      _showSnack('Vui lòng chọn tỉnh/thành');
      return;
    }
    if (selectedDistricts.isEmpty) {
      _showSnack('Vui lòng chọn ít nhất một quận/huyện');
      return;
    }
    // SỬA Ở ĐÂY: Kiểm tra selectedServiceIds thay vì services
    if (selectedServiceIds.isEmpty) {  // Đổi từ services.isEmpty thành selectedServiceIds.isEmpty
      _showSnack('Vui lòng chọn ít nhất một dịch vụ');
      return;
    }
    // if (bio.isEmpty) {
    //   _showSnack('Vui lòng nhập giới thiệu bản thân');
    //   return;
    // }

    setState(() => isLoading = true);

    try {
      final data = {
        'fullName': fullname,
        'province': selectedProvince['name'],
        'districts': selectedDistricts.map((d) => d['name']).toList(),
        'address': address,
        'experience': experience,
        'gender': gender,
        'images': images,
        'serviceIds': selectedServiceIds.map((s) => s['_id']).toList(), // Dòng này vẫn đúng
        'yearOfBirth': yearOfBirth,
        if (avatarImage != null) 'avatar': avatarImage,
      };

      final response = await technicianService.updateTechnicianService(
        widget.data['technician']['_id'],
        data,
      );

      if (response['success'] == true) {
        _showSnack('Cập nhật hồ sơ kĩ thuật viên thành công', isError: false);
        context.pop(true);
      } else {
        _showSnack(response['message'] ?? 'Có lỗi xảy ra khi cập nhật hồ sơ');
      }
    } catch (e) {
      _showSnack('Lỗi hệ thống: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> uploadImage(String filePath, {bool isAvatar = false}) async {
    try {
      final uploadService = UploadService();
      final response = await uploadService.uploadSingleFileService(filePath);
      final imageData = response['data'];

      if (imageData != null) {
        setState(() {
          if (isAvatar) {
            avatarImage = imageData;
          } else {
            if (images.length < 5) {
              images.add(imageData);
            } else {
              _showSnack('Chỉ được tối đa 5 ảnh');
            }
          }
        });
      } else {
        _showSnack('Không thể tải lên hình ảnh');
      }
    } catch (e) {
      _showSnack('Lỗi tải lên hình ảnh: $e');
    }
  }

  Future<void> _pickImage({bool isAvatar = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (isAvatar) {
        await _cropImage(File(pickedFile.path), isAvatar: true);
      } else {
        if (images.length >= 5) {
          _showSnack('Chỉ được tối đa 5 ảnh');
          return;
        }
        await uploadImage(pickedFile.path);
      }
    }
  }

  Future<void> _cropImage(File imageFile, {bool isAvatar = false}) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt ảnh',
          toolbarColor: const Color(0xFF8B5E3C),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Cắt ảnh',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (croppedFile != null) {
      await uploadImage(croppedFile.path, isAvatar: isAvatar);
    }
  }

  Future<void> deleteImage(String idImage) async {
    try {
      final fileService = FileService();
      final response = await fileService.deleteFileService(idImage);

      if (response['status'] == 'success') {
        _showSnack('Hình ảnh đã được xóa', isError: false);
        setState(() => images.removeWhere((img) => img['_id'] == idImage));
      } else {
        _showSnack('Không thể xóa hình ảnh');
      }
    } catch (e) {
      _showSnack('Lỗi xóa hình ảnh: $e');
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(child: Image.network(imageUrl, fit: BoxFit.contain)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, size: 30, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: ColorConfig.textWhite),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== UI Components ====================

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: () {
                  if (avatarImage != null) {
                    _showFullScreenImage(
                      FormatHelper.formatNetworkImageUrl(avatarImage!['url']),
                    );
                  }
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ColorConfig.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatarImage != null
                        ? Image.network(
                      FormatHelper.formatNetworkImageUrl(avatarImage!['url']),
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    )
                        : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
              if (avatarImage != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      avatarImage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _pickImage(isAvatar: true),
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Chọn ảnh đại diện', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConfig.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey[50],
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
              borderSide: const BorderSide(color: Color(0xFF8B5E3C), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableField({
    required String label,
    required String? value,
    required VoidCallback onTap,
    required IconData icon,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: ColorConfig.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: value != null ? const Color(0xFF333333) : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5E3C)),
                ),
              )
            else
              Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSection() {
    final genderOptions = [
      {'value': 'male', 'label': 'Nam', 'icon': Icons.male_rounded},
      {'value': 'female', 'label': 'Nữ', 'icon': Icons.female_rounded},
      {'value': 'other', 'label': 'Khác', 'icon': Icons.person_outline_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giới tính',
          style: TextStyle(fontSize: 14, color: ColorConfig.textBlack),
        ),
        const SizedBox(height: 10),
        Row(
          children: genderOptions.map((option) {
            final isSelected = selectedGender == option['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedGender = option['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                    right: option['value'] != 'other' ? 10 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorConfig.primary : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: isSelected ? ColorConfig.primary : const Color(0xFFE8E8E8),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        option['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : const Color(0xFF888888),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        option['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required dynamic value,
    required List<dynamic> items,
    required Function(dynamic) onChanged,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<dynamic>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item['name'], style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: isLoading ? null : onChanged,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required String label,
    required String? value,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: value != null ? const Color(0xFF333333) : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5E3C)),
                ),
              )
            else
              Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: images.length + (images.length < 5 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == images.length) {
          return GestureDetector(
            onTap: () => _pickImage(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm ảnh',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }

        final image = images[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(
                  FormatHelper.formatNetworkImageUrl(image['url']),
                ),
                child: Image.network(
                  FormatHelper.formatNetworkImageUrl(image['url']),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => deleteImage(image['_id']),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
  // ==================== Bottom Sheets ====================

  Widget _buildBottomSheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _showExperienceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetHandle(),
              const SizedBox(height: 20),
              const Text(
                'Chọn kinh nghiệm',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: experiences.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final exp = experiences[index];
                    return ListTile(
                      title: Text(exp, style: const TextStyle(fontSize: 16)),
                      onTap: () {
                        setState(() => experience = exp);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showYearOfBirthBottomSheet() {
    final currentYear = DateTime.now().year;
    final years = List.generate(60, (index) => currentYear - index - 18);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetHandle(),
              const SizedBox(height: 20),
              const Text(
                'Chọn năm sinh',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: years.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final year = years[index];
                    return ListTile(
                      title: Text(year.toString(), style: const TextStyle(fontSize: 16)),
                      onTap: () {
                        setState(() => yearOfBirth = year);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDistrictBottomSheet() {
    if (selectedProvince == null) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn tỉnh/thành phố trước');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBottomSheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Chọn quận/huyện',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _districtSearchController,
                    onChanged: (value) {
                      setStateModal(() {
                        filteredDistricts = districts.where((district) {
                          return district['name']
                              .toLowerCase()
                              .contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm quận/huyện',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredDistricts.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final district = filteredDistricts[index];
                        final isSelected = selectedDistricts.contains(district);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            district['name'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF333333) : Colors.grey[700],
                            ),
                          ),
                          value: isSelected,
                          activeColor: ColorConfig.primary,
                          onChanged: (bool? value) {
                            setStateModal(() {
                              if (value == true) {
                                selectedDistricts.add(district);
                              } else {
                                selectedDistricts.remove(district);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConfig.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text('Xác nhận', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showServicesBottomSheet() {
    _serviceSearchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBottomSheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Chọn dịch vụ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn các dịch vụ kỹ thuật viên có thể cung cấp',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _serviceSearchController,
                    onChanged: (value) {
                      setStateModal(() {
                        filteredServices = allServices!.where((service) {
                          return service['name']
                              .toLowerCase()
                              .contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm dịch vụ',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredServices.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Không tìm thấy dịch vụ',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                        : ListView.separated(
                      itemCount: filteredServices.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final service = filteredServices[index];
                        final isSelected = selectedServiceIds.any(
                                (s) => s['_id'] == service['_id']
                        );
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            service['name'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? ColorConfig.textBlack : Colors.grey[700],
                            ),
                          ),
                          subtitle: service['description'] != null
                              ? Text(
                            service['description'],
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                              : null,
                          value: isSelected,
                          activeColor: ColorConfig.primary,
                          onChanged: (bool? value) {
                            setStateModal(() {
                              if (value == true) {
                                selectedServiceIds.add(service);
                              } else {
                                selectedServiceIds.removeWhere(
                                        (s) => s['_id'] == service['_id']
                                );
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConfig.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text('Xác nhận', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getDistrictsDisplayText() {
    if (selectedDistricts.isEmpty) return 'Chọn quận/huyện';
    final districtNames = selectedDistricts.map((d) => d['name']).toList();
    if (districtNames.length == 1) return districtNames.first;
    return '${districtNames.first} và ${districtNames.length - 1} quận/huyện khác';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cập nhật thông tin kỹ thuật viên",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 24),

                // Thông tin cơ bản
                _buildSectionTitle('Thông tin cơ bản'),
                _buildTextField(
                  controller: fullnameController,
                  label: 'Họ và tên *',
                  hint: 'Nhập họ và tên đầy đủ',
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Năm sinh',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSelectableField(
                            label: 'Chọn năm sinh',
                            value: yearOfBirth?.toString(),
                            onTap: _showYearOfBirthBottomSheet,
                            icon: Icons.cake,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Expanded(
                    //   child: _buildGenderRadio(),
                    // ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kinh nghiệm',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSelectableField(
                            label: 'Chọn kinh nghiệm',
                            value: experience,
                            onTap: _showExperienceBottomSheet,
                            icon: Icons.work,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildGenderSection(),

                const SizedBox(height: 16),
                Row(
                  children: [
                    // Expanded(
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       const Text(
                    //         'Kinh nghiệm',
                    //         style: TextStyle(
                    //           color: Color(0xFF333333),
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //       const SizedBox(height: 8),
                    //       _buildSelectableField(
                    //         label: 'Chọn kinh nghiệm',
                    //         value: experience,
                    //         onTap: _showExperienceBottomSheet,
                    //         icon: Icons.work,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Tỉnh/Thành phố',
                        value: selectedProvince,
                        items: provinces,
                        onChanged: (value) {
                          setState(() {
                            selectedProvince = value;
                            selectedDistricts.clear();
                          });
                          _loadDistricts(value['id']);
                        },
                        isLoading: isProvincesLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quận/Huyện - 1 dòng riêng
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quận/Huyện',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationField(
                      label: 'Chọn quận/huyện',
                      value: selectedDistricts.isEmpty
                          ? null
                          : '${selectedDistricts.length} đã chọn',
                      onTap: _showDistrictBottomSheet,
                      isLoading: isDistrictsLoading,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Địa chỉ cụ thể - 2 line riêng
                _buildTextField(
                  controller: addressController,
                  label: 'Địa chỉ cụ thể *',
                  hint: 'Số nhà, tên đường, thôn/xóm...',
                  maxLines: 2,
                ),
                const SizedBox(height: 10),

                _buildSectionTitle('Dịch vụ cung cấp'),
                _buildLocationField(
                  label: 'Chọn dịch vụ',
                  value: selectedServiceIds.isEmpty
                      ? null
                      : '${selectedServiceIds.length} dịch vụ',
                  onTap: _showServicesBottomSheet,
                ),
                const SizedBox(height: 16),

                _buildSectionTitle('Hình ảnh (tối đa 5 ảnh)'),
                const SizedBox(height: 8),
                _buildImageGrid(),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/home-admin'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: const Text(
                          "Hủy bỏ",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConfig.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : handleUpdateTechnician,
                        child: isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          "Cập nhật",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fullnameController.dispose();
    addressController.dispose();
    bioController.dispose();
    _districtSearchController.dispose();
    _serviceSearchController.dispose();
    super.dispose();
  }
}