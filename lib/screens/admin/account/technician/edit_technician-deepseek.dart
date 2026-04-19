import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';

import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/tinhthanh_service_v2.dart';
import 'package:spa_app/services/upload_service.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

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

  // State variables
  bool isLoading = false;
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> filteredDistricts = [];
  List<dynamic> filteredProvinces = [];
  dynamic selectedProvince;
  List<dynamic> selectedDistricts = [];
  String? experience;
  List<Map<String, dynamic>> images = [];
  Map<String, dynamic>? avatarImage;
  List<String> services = [];
  List<String> availableServices = ['Đá nóng', 'Giác hơi', 'Massage'];
  final experiences = [
    '1 năm',
    '2 năm',
    '3 năm',
    '4 năm',
    '5 năm',
    '6 năm',
    '7 năm',
    '8 năm',
    '9 năm',
    '10 năm'
  ];
  final years = List.generate(80, (index) => DateTime.now().year - 18 - index);
  int? yearOfBirth;

  bool isProvincesLoading = false;
  bool isDistrictsLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadProvinces();
  }

  void _initializeData() {
    print('Initializing data: ${widget.data}');
    final technicianData = widget.data['technician'];

    fullnameController.text = technicianData['fullName'] ?? '';
    addressController.text = technicianData['address'] ?? '';
    bioController.text = technicianData['bio'] ?? '';
    experience = technicianData['experience'] ?? '3 năm';
    yearOfBirth = technicianData['yearOfBirth'];
    services = List<String>.from(technicianData['services'] ?? []);

    if (technicianData['avatar'] != null) {
      avatarImage = {
        '_id': technicianData['avatar']['_id'],
        'url': technicianData['avatar']['url'],
        'uploadedAt': technicianData['avatar']['uploadedAt'],
      };
    }

    if (technicianData['images'] != null && technicianData['images'].isNotEmpty) {
      images = List<Map<String, dynamic>>.from(
          technicianData['images'].map((img) => {
            '_id': img['_id'],
            'url': img['url'],
            'uploadedAt': img['uploadedAt'],
          }));
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => isProvincesLoading = true);
    try {
      final listTinhThanh = await tinhThanhService.getTinhThanh();
      print("List tỉnh thành: ${listTinhThanh}");
      if (listTinhThanh.isEmpty) {
        SnackBarHelper.showError(context, 'Không thể tải danh sách tỉnh thành');
      } else {
        setState(() {
          provinces = listTinhThanh;
          filteredProvinces = provinces;
          if (widget.data['technician']['province'] != null) {
            selectedProvince = provinces.firstWhereOrNull(
                  (prov) => prov['name'] == widget.data['technician']['province'],
            );
            if (selectedProvince != null) {
              _loadDistricts(selectedProvince['id']);
            }
          }
        });
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi tải tỉnh thành: $e');
      print("Lỗi tải tỉnh thành: $e");
    } finally {
      setState(() => isProvincesLoading = false);
    }
  }

  Future<void> _loadDistricts(int idProvince) async {
    setState(() => isDistrictsLoading = true);
    try {
      final listQuanHuyen = await tinhThanhService.getHuyenByTinh(idProvince);
      print("List quận huyện: ${listQuanHuyen}");
      if (listQuanHuyen.isEmpty) {
        SnackBarHelper.showError(context, 'Không thể tải danh sách huyện');
      } else {
        setState(() {
          districts = listQuanHuyen;
          filteredDistricts = districts;
          if (widget.data['technician']['districts'] != null) {
            selectedDistricts = districts
                .where((district) => widget.data['technician']['districts']
                .contains(district['name']))
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
    if (services.isEmpty) {
      _showSnack('Vui lòng chọn ít nhất một dịch vụ');
      return;
    }
    if (yearOfBirth == null) {
      _showSnack('Vui lòng chọn năm sinh');
      return;
    }
    if (experience == null) {
      _showSnack('Vui lòng chọn kinh nghiệm');
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = {
        'fullName': fullname,
        'province': selectedProvince['name'],
        'districts': selectedDistricts.map((d) => d['name']).toList(),
        'address': address,
        'experience': experience,
        'images': images,
        'services': services,
        'bio': bio,
        'yearOfBirth': yearOfBirth,
        if (avatarImage != null) 'avatar': avatarImage,
      };

      final response = await technicianService.updateTechnicianService(
          widget.data['technician']['_id'], data);

      if (response['success'] == true) {
        _showSnack('Cập nhật hồ sơ kĩ thuật viên thành công', isError: false);
        context.go('/home-admin');
      } else {
        _showSnack(response['message'] ?? 'Có lỗi xảy ra khi cập nhật hồ sơ');
        print('Lỗi khi cập nhật hồ sơ: ${response['message']}');
      }
    } catch (e) {
      print('Lỗi khi cập nhật hồ sơ: $e');
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
            images.add(imageData);
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
        content: Text(message, style: GoogleFonts.lora(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required dynamic value,
    required List<dynamic> items,
    required Function(dynamic) onChanged,
    bool isLoading = false,
    bool isMultiSelect = false,
  }) {
    if (isMultiSelect) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: DropdownButtonFormField<dynamic>(
          value: null,
          isExpanded: true,
          decoration: InputDecoration.collapsed(
            hintText: '${selectedDistricts.length} quận/huyện đã chọn',
            hintStyle: GoogleFonts.lora(color: const Color(0xFF8B5E3C)),
          ),
          items: items.map((item) {
            final isSelected = selectedDistricts
                .any((d) => d['id'] == item['id']);
            return DropdownMenuItem(
              value: item,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CheckboxListTile(
                    title: Text(item['name'], style: GoogleFonts.lora()),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedDistricts.add(item);
                        } else {
                          selectedDistricts
                              .removeWhere((d) => d['id'] == item['id']);
                        }
                      });
                    },
                  );
                },
              ),
            );
          }).toList(),
          onChanged: (value) {},
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<dynamic>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(label, style: GoogleFonts.lora(color: const Color(0xFF8B5E3C))),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item is Map ? item['name'] : item.toString(),
              style: GoogleFonts.lora(),
            ),
          );
        }).toList(),
        onChanged: isLoading ? null : onChanged,
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (avatarImage != null) {
              _showFullScreenImage(
                  FormatHelper.formatImageUrl(avatarImage!['url']));
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
                    FormatHelper.formatImageUrl(avatarImage!['url']),
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
                      child: const Icon(Icons.close, size: 20, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 20),
      ],
    );
  }

  // void _showExperienceBottomSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) => Container(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             'Chọn kinh nghiệm',
  //             style: ThemeConfig.appTextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           SizedBox(
  //             height: 300,
  //             child: ListView(
  //               children: experiences.map((exp) {
  //                 return ListTile(
  //                   title: Text(exp),
  //                   onTap: () {
  //                     setState(() => experience = exp);
  //                     Navigator.pop(context);
  //                   },
  //                 );
  //               }).toList(),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // void _showYearBottomSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) => Container(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             'Chọn năm sinh',
  //             style: ThemeConfig.appTextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           SizedBox(
  //             height: 300,
  //             child: ListView(
  //               children: years.map((year) {
  //                 return ListTile(
  //                   title: Text(year.toString()),
  //                   onTap: () {
  //                     setState(() => yearOfBirth = year);
  //                     Navigator.pop(context);
  //                   },
  //                 );
  //               }).toList(),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showDistrictBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn quận/huyện',
              style: ThemeConfig.appTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView(
                children: districts.map((district) {
                  final isSelected = selectedDistricts
                      .any((d) => d['id'] == district['id']);
                  return CheckboxListTile(
                    title: Text(district['name']),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedDistricts.add(district);
                        } else {
                          selectedDistricts.removeWhere(
                                  (d) => d['id'] == district['id']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Xong'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: const Color(0xFF8B5E3C)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? label,
                style: GoogleFonts.lora(
                  color: value != null ? Colors.black87 : const Color(0xFF8B5E3C),
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dịch vụ cung cấp',
          style: GoogleFonts.lora(fontSize: 16, color: const Color(0xFF8B5E3C)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableServices.map((service) {
            final isSelected = services.contains(service);
            return FilterChip(
              label: Text(service),
              selected: isSelected,
              onSelected: (bool value) {
                setState(() {
                  if (value) {
                    services.add(service);
                  } else {
                    services.remove(service);
                  }
                });
              },
              selectedColor: const Color(0xFFD4A373),
              checkmarkColor: Colors.white,
              labelStyle: GoogleFonts.lora(
                color: isSelected ? Colors.white : const Color(0xFF8B5E3C),
              ),
            );
          }).toList(),
        ),
      ],
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
              onTap: () =>
                  _showFullScreenImage(FormatHelper.formatImageUrl(image['url'])),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  FormatHelper.formatImageUrl(image['url']),
                  fit: BoxFit.cover,
                ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    // int maximization = 1,
    int? maxLength,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      // maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8B5E3C)),
        labelStyle: GoogleFonts.lora(
          color: const Color(0xFF8B5E3C),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4A373), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      style: GoogleFonts.lora(color: Colors.black87, fontSize: 16),
    );
  }

  String _truncateDistricts(List<dynamic> districts) {
    if (districts.isEmpty) return '';
    final firstDistrict = districts[0]['name'] as String;
    return districts.length > 1
        ? '${firstDistrict.substring(0, min(firstDistrict.length, 10))}...'
        : firstDistrict;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F4E9), Color(0xFFE9D8C8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                _buildAvatarSection(),

                // Full Name
                _buildTextField(
                  controller: fullnameController,
                  label: 'Họ và tên',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),

                // Year of Birth and Experience (combined in one row)
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Năm sinh',
                        value: yearOfBirth,
                        items: years,
                        onChanged: (value) {
                          setState(() => yearOfBirth = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Kinh nghiệm',
                        value: experience,
                        items: experiences,
                        onChanged: (value) {
                          setState(() => experience = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Province and Districts (combined in one row)
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Chọn tỉnh/thành',
                        value: selectedProvince,
                        items: provinces,
                        onChanged: (value) {
                          setState(() {
                            selectedProvince = value;
                            selectedDistricts.clear();
                          });
                          _loadDistricts(value['idProvince']);
                        },
                        isLoading: isProvincesLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLocationField(
                        label: 'Quận/Huyện',
                        value: _truncateDistricts(selectedDistricts),
                        onTap: _showDistrictBottomSheet,
                        isLoading: isDistrictsLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Address
                _buildTextField(
                  controller: addressController,
                  label: 'Địa chỉ cụ thể',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),

                // Services
                _buildServicesSection(),
                const SizedBox(height: 16),

                // Bio
                _buildTextField(
                  controller: bioController,
                  label: 'Giới thiệu bản thân (tối đa 100 ký tự)',
                  icon: Icons.info,
                  // maxLines: 3,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Images
                Text(
                  'Hình ảnh (tối đa 5 ảnh)',
                  style: GoogleFonts.lora(fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildImageGrid(),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/home-admin'),
                        icon: Icon(Icons.chevron_left, color: ColorConfig.grey),
                        label: Text("Hủy", style: TextStyle(color: ColorConfig.grey)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConfig.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isLoading ? null : handleUpdateTechnician,
                        label: isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text("Lưu",
                            style: TextStyle(color: ColorConfig.textWhite)),
                        icon: isLoading
                            ? const SizedBox()
                            : Icon(Icons.chevron_right,
                            color: ColorConfig.textWhite),
                      ),
                    ),
                  ],
                ),
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
    super.dispose();
  }
}