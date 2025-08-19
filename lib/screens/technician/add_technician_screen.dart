import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/tinhthanh_service_v2.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';

class AddTechnicianScreen extends StatefulWidget {
  const AddTechnicianScreen({super.key});

  @override
  State<AddTechnicianScreen> createState() => _AddTechnicianScreen();
}

class _AddTechnicianScreen extends State<AddTechnicianScreen> {
  final fullnameController = TextEditingController();
  final addressController = TextEditingController();
  final experienceDescriptionController = TextEditingController();
  final bioController = TextEditingController();
  final technicianService = TechnicianService();
  final tinhThanhService = TinhThanhService();

  bool isLoading = false;
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  dynamic selectedProvince;
  List<dynamic> selectedDistricts = [];
  String? selectedYear;
  dynamic selectedCommune;
  String? experience;
  List<Map<String, dynamic>> images = [];
  Map<String, dynamic>? avatarImage;

  final _provinceSearchController = TextEditingController();
  final _districtSearchController = TextEditingController();
  final _communeSearchController = TextEditingController();
  final _experienceSearchController = TextEditingController();

  List<dynamic> filteredProvinces = [];
  List<dynamic> filteredDistricts = [];
  List<dynamic> filteredCommunes = [];

  bool isProvincesLoading = false;
  bool isDistrictsLoading = false;
  bool isCommunesLoading = false;

  final Map<String, bool> services = {
    'Đá nóng': false,
    'Giác hơi': false,
    'Cạo gió': false,
  };

  final List<String> years = List.generate(
    50, (index) => (DateTime.now().year - 49 + index).toString(),
  );

  @override
  void initState() {
    super.initState();
    _provinceSearchController.addListener(_filterProvinces);
    _districtSearchController.addListener(_filterDistricts);
    _loadProvinces();
  }

  @override
  void dispose() {
    _provinceSearchController.dispose();
    _districtSearchController.dispose();
    _communeSearchController.dispose();
    _experienceSearchController.dispose();
    fullnameController.dispose();
    addressController.dispose();
    // experienceDescriptionController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void _filterProvinces() {
    final query = _provinceSearchController.text.toLowerCase();
    setState(() {
      filteredProvinces = provinces.where((province) {
        return province['name'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  void _filterDistricts() {
    final query = _districtSearchController.text.toLowerCase();
    setState(() {
      filteredDistricts = districts.where((district) {
        return district['name'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadProvinces() async {
    setState(() => isProvincesLoading = true);
    try {
      final listTinhThanh = await tinhThanhService.getTinhThanh();
      // print("DS Tinh thanh: $listTinhThanh");
      if (listTinhThanh.isEmpty) {
        SnackbarHelper.showError(context, 'Không thể tải danh sách tỉnh thành');
      } else {
        setState(() {
          provinces = listTinhThanh;
          filteredProvinces = provinces;
        });
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Lỗi tải tỉnh thành: $e');
    } finally {
      setState(() => isProvincesLoading = false);
    }
  }

  Future<void> _loadDistricts(int idProvince) async {
    setState(() {
      isDistrictsLoading = true;
      districts = [];
      filteredDistricts = [];
      filteredCommunes = [];
      selectedDistricts.clear();
      selectedCommune = null;
    });

    try {
      final listQuanHuyen = await tinhThanhService.getHuyenByTinh(idProvince);
      if (listQuanHuyen.isEmpty) {
        SnackbarHelper.showError(context, 'Không thể tải danh sách huyện');
      } else {
        setState(() {
          districts = listQuanHuyen;
          filteredDistricts = districts;
        });
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Lỗi tải huyện: $e');
    } finally {
      setState(() => isDistrictsLoading = false);
    }
  }

  Future<void> handleCreateTechnician() async {
    final fullname = fullnameController.text.trim();
    final address = addressController.text.trim();
    // final experienceDesc = experienceDescriptionController.text.trim();
    final bio = bioController.text.trim();

    if (fullname.isEmpty) {
      SnackbarHelper.showWarning(context, 'Vui lòng nhập họ tên');
      return;
    }
    if (selectedProvince == null || selectedDistricts.isEmpty) {
      SnackbarHelper.showWarning(context, 'Vui lòng chọn đầy đủ địa chỉ');
      return;
    }
    if (address.isEmpty) {
      SnackbarHelper.showWarning(context, 'Vui lòng nhập địa chỉ nơi ở');
      return;
    }
    if (selectedYear == null) {
      SnackbarHelper.showWarning(context, 'Vui lòng chọn năm sinh');
      return;
    }
    if (experience == null) {
      SnackbarHelper.showWarning(context, 'Vui lòng chọn kinh nghiệm');
      return;
    }
    if (images.length < 3) {
      SnackbarHelper.showWarning(context, 'Vui lòng chọn tối thiểu 3 ảnh');
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = {
        'avatar': avatarImage,
        'fullName': fullname,
        'province': selectedProvince['name'],
        'districts': selectedDistricts.map((d) => d['name']).toList(),
        'address': address,
        'yearOfBirth': int.tryParse(selectedYear.toString()),
        'experience': experience,
        'services': services.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList(),
        'images': images,
        'bio': bio,
      };


      final response = await technicianService.addTechnicianService(data);
      if (response['success'] == true) {
        SnackbarHelper.showSuccess(context, 'Đã thêm hồ sơ vui lòng chờ duyệt');
        context.go('/home-technician');
      } else {
        SnackbarHelper.showError(
            context, response['message'] ?? 'Có lỗi xảy ra khi tạo hồ sơ');
        print('Lỗi khi tạo hồ sơ: ${response['message']}');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Lỗi hệ thống: $e');
      print('Lỗi hệ thống: $e');
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
            images.add(imageData);
          }
        });
      } else {
        SnackbarHelper.showError(context, 'Không thể tải lên hình ảnh');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Lỗi tải lên hình ảnh: $e');
    }
  }

  Future<void> _pickImage({bool isAvatar = false}) async {
    if (!isAvatar && images.length >= 5) {
      SnackbarHelper.showError(context, 'Bạn chỉ được chọn tối đa 5 ảnh');
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _cropImage(File(pickedFile.path), isAvatar: isAvatar);
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
        SnackbarHelper.showSuccess(context, 'Hình ảnh đã được xóa');
        setState(() => images.removeWhere((img) => img['_id'] == idImage));
      } else {
        SnackbarHelper.showError(context, 'Không thể xóa hình ảnh');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Lỗi xóa hình ảnh: $e');
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
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

  Widget _buildLocationField({
    required String label,
    required String? value,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1.0, // viền mỏng
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? label,
                  style: ThemeConfig.appTextStyle(
                    color: value != null
                        ? ColorConfig.textPrimary
                        : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }


  void _showProvinceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildLocationBottomSheet(
        title: 'Chọn tỉnh',
        controller: _provinceSearchController,
        items: filteredProvinces,
        onSelected: (province) {
          setState(() {
            selectedProvince = province;
            selectedDistricts.clear();
          });
          _loadDistricts(province['id']);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDistrictBottomSheet() {
    if (selectedProvince == null) {
      SnackbarHelper.showWarning(context, 'Vui lòng chọn tỉnh trước');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn quận *',
                  style: ThemeConfig.appTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _districtSearchController,
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredDistricts.length,
                    itemBuilder: (context, index) {
                      final district = filteredDistricts[index];
                      final isSelected = selectedDistricts.contains(district);
                      return CheckboxListTile(
                        title: Text(district['name']),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedDistricts.add(district);
                            } else {
                              selectedDistricts.remove(district);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConfig.secondary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showExperienceBottomSheet() {
    final experiences = [
      '1 năm', '2 năm', '3 năm', '4 năm', '5 năm',
      '6 năm', '7 năm', '8 năm', '9 năm', '10 năm'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn kinh nghiệm',
              style: ThemeConfig.appTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView(
                children: experiences.map((exp) {
                  return ListTile(
                    title: Text(exp),
                    onTap: () {
                      setState(() => experience = exp);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showYearBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Chọn năm sinh',
              style: ThemeConfig.appTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(years[index]),
                    onTap: () {
                      setState(() => selectedYear = years[index]);
                      Navigator.pop(context);
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

  Widget _buildLocationBottomSheet({
    required String title,
    required TextEditingController controller,
    required List<dynamic> items,
    required Function(dynamic) onSelected,
  }) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: ThemeConfig.appTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Tìm kiếm',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item['name']),
                  onTap: () => onSelected(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length + (images.length < 5 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == images.length) {
          return GestureDetector(
            onTap: () => _pickImage(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
            ),
          );
        }

        final image = images[index];
        return Stack(
          children: [
            GestureDetector(
              onTap: () => FullScreenSingleImageViewer(imageUrl: image['url']),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(image['url'], fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => deleteImage(image['_id']),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (avatarImage != null) {
              _showFullScreenImage(avatarImage!['url']);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4A373), width: 2),
                ),
                child: ClipOval(
                  child: avatarImage != null
                      ? Image.network(
                    avatarImage!['url'],
                    fit: BoxFit.cover,
                    width: 110,
                    height: 110,
                  )
                      : const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
              ),
              if (avatarImage != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        avatarImage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child:
                      const Icon(Icons.close, size: 20, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _pickImage(isAvatar: true),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Chọn ảnh đại diện'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4A373),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dịch vụ cung cấp', style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: services.entries.map((service) {
            return FilterChip(
              // label: Text(service.key, style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary)),
              label: Text(service.key),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              selected: service.value,
              onSelected: (bool value) {
                setState(() {
                  services[service.key] = value;
                });
              },
              selectedColor: ColorConfig.secondary,
              checkmarkColor: ColorConfig.white,
              labelStyle: ThemeConfig.appTextStyle(
                color: service.value ? ColorConfig.textWhite : ColorConfig.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.white,
      resizeToAvoidBottomInset: true,
      body: Container(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              Center(
                child: Text(
                  'Giới thiệu kĩ thuật viên',
                  style: ThemeConfig.appTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConfig.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildAvatarSection(),
              const SizedBox(height: 7),
              _buildTextField(
                controller: fullnameController,
                label: 'Họ và tên',
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thành phố làm việc',
                          style: ThemeConfig.appTextStyle(
                            color: ColorConfig.textPrimary, fontSize: 14
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildLocationField(
                          label: 'Thành phố',
                          value: selectedProvince?['name'],
                          onTap: _showProvinceBottomSheet,
                          isLoading: isProvincesLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn quận/Huyện',
                          style: ThemeConfig.appTextStyle(
                            color: ColorConfig.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildLocationField(
                          label: selectedDistricts.isEmpty
                              ? 'Quận/Huyện'
                              : '${selectedDistricts.length} đã chọn',
                          value: selectedDistricts.isEmpty
                              ? null
                              : (() {
                            String text = selectedDistricts
                                .map((d) => d['name'])
                                .join(', ');
                            int maxLength = selectedDistricts.length > 1 ? 15 : 30;
                            return text.length > maxLength
                                ? text.substring(0, maxLength) + '...'
                                : text;
                          })(),
                          onTap: _showDistrictBottomSheet,
                          isLoading: isDistrictsLoading,
                        ),
                      ],
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: addressController,
                label: 'Địa chỉ nơi ở',
                hint: 'Số nhà, đường, phường, xã, thành phố, tỉnh...',
                maxLines: 1,
              ),
              const SizedBox(height: 7),

              Row(
                children: [
                  Expanded(
                    child: _buildLocationField(
                      label: 'Năm sinh',
                      value: selectedYear,
                      onTap: _showYearBottomSheet,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _buildLocationField(
                      label: 'Kinh nghiệm',
                      value: experience,
                      onTap: _showExperienceBottomSheet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: bioController,
                label: 'Giới thiệu thêm',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildServicesSection(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hình ảnh (3-5 ảnh)',
                      style: ThemeConfig.appTextStyle(
                        color: ColorConfig.textPrimary,
                      ),
                    ),
                  ),
                  if (images.isNotEmpty)
                    Text(
                      '(${images.length}/5)',
                      style: ThemeConfig.appTextStyle(
                        color: ColorConfig.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildImageGrid(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: Icon(Icons.chevron_left, color: ColorConfig.grey),
                      label: Text("Hủy", style: TextStyle(color: ColorConfig.grey)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConfig.secondary,
                      ),
                      onPressed: isLoading ? null : handleCreateTechnician,
                      label: Text("Tạo hồ sơ", style: TextStyle(color: ColorConfig.textWhite)),
                      icon: Icon(Icons.chevron_right, color: ColorConfig.textWhite),
                    ),
                  ),
                ],
              )

            ],
          ),
        ),
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
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFFD4A373), width: 1),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary),
    );
  }
}