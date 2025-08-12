import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/tinhthanh_service.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/services/user_service.dart';

class UserEditTechnicianScreen extends StatefulWidget {
  const UserEditTechnicianScreen({super.key});

  @override
  State<UserEditTechnicianScreen> createState() => _UserEditTechnicianScreenState();
}

class _UserEditTechnicianScreenState extends State<UserEditTechnicianScreen> {
  final UserService userService = UserService();
  final fullnameController = TextEditingController();
  final addressController = TextEditingController();
  final experienceDescriptionController = TextEditingController();
  final bioController = TextEditingController();
  final technicianService = TechnicianService();
  final tinhThanhService = TinhThanhService();

  // State variables
  bool isLoading = false;
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> communes = [];
  dynamic selectedProvince;
  dynamic selectedDistrict;
  dynamic selectedCommune;
  String? experience;
  List<Map<String, dynamic>> images = [];
  Map<String, dynamic>? avatarImage;
  Map<String, dynamic>? dataUser;
  Map<String, dynamic>? technicianData;

  // Dropdown loading states
  bool isProvincesLoading = false;
  bool isDistrictsLoading = false;
  bool isCommunesLoading = false;

  late String originalProvince;
  late String originalDistrict;
  late String originalCommune;
  late String originalAddress;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  Future<void> _loadUserDetail() async {
    setState(() => isLoading = true);
    try {
      final response = await userService.loadDetailUserService();
      if (response['success'] == true) {
        setState(() {
          dataUser = response['data'];
          technicianData = response['data']['technician'];
          _initializeData();
        });
        await _loadProvinces();
      } else {
        _showSnack('Không thể tải thông tin người dùng');
      }
    } catch (e) {
      _showSnack('Lỗi tải thông tin: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _initializeData() {
    if (technicianData == null) return;

    // Set initial values from the data
    fullnameController.text = technicianData?['fullName'] ?? '';
    addressController.text = technicianData?['address'] ?? '';
    experienceDescriptionController.text = technicianData?['experienceDescription'] ?? '';
    bioController.text = technicianData?['bio'] ?? '';
    experience = technicianData?['experience'] ?? 'Có kinh nghiệm';

    originalProvince = technicianData?['province'] ?? '';
    originalDistrict = technicianData?['district'] ?? '';
    originalCommune = technicianData?['commune'] ?? '';
    originalAddress = technicianData?['address'] ?? '';

    // Set avatar if exists
    if (technicianData?['avatar'] != null) {
      avatarImage = {
        '_id': technicianData!['avatar']['_id'],
        'url': technicianData!['avatar']['url'],
        'createdAt': technicianData!['avatar']['uploadedAt'] ?? technicianData!['avatar']['createdAt']
      };
    }

    // Set images if exist
    if (technicianData?['images'] != null && technicianData!['images'].isNotEmpty) {
      images = List<Map<String, dynamic>>.from(technicianData!['images'].map((img) => {
        '_id': img['_id'],
        'url': img['url'],
        'createdAt': img['uploadedAt'] ?? img['createdAt']
      })).toList();
    }

    // Set initial location data
    _setInitialLocationData();
  }

  void _setInitialLocationData() {
    if (technicianData == null) return;

    final provinceName = technicianData!['province'];
    final districtName = technicianData!['district'];
    final communeName = technicianData!['commune'];

    if (provinceName != null && provinces.isNotEmpty) {
      final province = provinces.firstWhere(
            (p) => p['name'] == provinceName,
        orElse: () => null,
      );
      if (province != null) {
        setState(() => selectedProvince = province);
        _loadDistricts(province['idProvince']).then((_) {
          if (districtName != null && districts.isNotEmpty) {
            final district = districts.firstWhere(
                  (d) => d['name'] == districtName,
              orElse: () => null,
            );
            if (district != null) {
              setState(() => selectedDistrict = district);
              _loadCommunes(district['idDistrict']).then((_) {
                if (communeName != null && communes.isNotEmpty) {
                  final commune = communes.firstWhere(
                        (c) => c['name'] == communeName,
                    orElse: () => null,
                  );
                  if (commune != null) {
                    setState(() => selectedCommune = commune);
                  }
                }
              });
            }
          }
        });
      }
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => isProvincesLoading = true);
    try {
      final response = await tinhThanhService.getDetailsTinhThanhApiRoutesService();
      if (response['code'] == 200 || response['status'] == 'success') {
        setState(() => provinces = response['data']);
      } else {
        _showSnack('Không thể tải danh sách tỉnh thành');
      }
    } catch (e) {
      _showSnack('Lỗi tải tỉnh thành: $e');
    } finally {
      setState(() => isProvincesLoading = false);
    }
  }

  Future<void> _loadDistricts(String provinceId) async {
    setState(() {
      isDistrictsLoading = true;
      districts = [];
      communes = [];
      selectedDistrict = null;
      selectedCommune = null;
    });

    try {
      final response = await tinhThanhService.getDetailsHuyenApiRoutesService(provinceId);
      if (response['code'] == 200 || response['status'] == 'success') {
        setState(() => districts = response['data']);
      } else {
        _showSnack('Không thể tải danh sách huyện');
      }
    } catch (e) {
      _showSnack('Lỗi tải huyện: $e');
    } finally {
      setState(() => isDistrictsLoading = false);
    }
  }

  Future<void> _loadCommunes(String districtId) async {
    setState(() {
      isCommunesLoading = true;
      communes = [];
      selectedCommune = null;
    });

    try {
      final response = await tinhThanhService.getDetailsXaApiRoutesService(districtId);
      if (response['code'] == 200 || response['status'] == 'success') {
        setState(() => communes = response['data']);
      } else {
        _showSnack('Không thể tải danh sách xã');
      }
    } catch (e) {
      _showSnack('Lỗi tải xã: $e');
    } finally {
      setState(() => isCommunesLoading = false);
    }
  }

  Future<void> handleUpdateTechnician() async {
    if (technicianData == null) return;

    final fullname = fullnameController.text.trim();
    final address = addressController.text.trim();
    final experienceDesc = experienceDescriptionController.text.trim();
    final bio = bioController.text.trim();

    // Validation
    if (fullname.isEmpty) {
      _showSnack('Vui lòng nhập họ tên');
      return;
    }
    if (address.isEmpty) {
      _showSnack('Vui lòng nhập địa chỉ cụ thể');
      return;
    }
    if (experience == null) {
      _showSnack('Vui lòng chọn kinh nghiệm');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Use selected values if available, otherwise use original values
      final province = selectedProvince != null ? selectedProvince['name'] : originalProvince;
      final district = selectedDistrict != null ? selectedDistrict['name'] : originalDistrict;
      final commune = selectedCommune != null ? selectedCommune['name'] : originalCommune;

      final data = {
        'avatar': avatarImage,
        'fullName': fullname,
        'province': province,
        'district': district,
        'commune': commune,
        'address': address,
        'experience': experience,
        'experienceDescription': experienceDesc,
        'images': images,
        'bio': bio,
      };

      final response = await technicianService.updateTechnicianService(technicianData!['_id'], data);
      if (response['success'] == true) {
        _showSnack('Cập nhật hồ sơ kĩ thuật viên thành công', isError: false);
        context.go('/home-technician');
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
            Center(
              child: Image.network(
                FormatHelper.formatImageUrl(imageUrl),
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
  }) {
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
            child: Text(item['name'], style: GoogleFonts.lora()),
          );
        }).toList(),
        onChanged: isLoading ? null : onChanged,
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
              onTap: () => _showFullScreenImage(image['url']),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  FormatHelper.formatImageUrl(image['url']),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
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
                    FormatHelper.formatImageUrl(avatarImage!['url']),
                    fit: BoxFit.cover,
                    width: 110,
                    height: 110,
                    loadingBuilder: (context, child, progress) {
                      return progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator());
                    },
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatarSection(),

                // Full Name
                _buildTextField(
                  controller: fullnameController,
                  label: 'Họ và tên',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),

                // Current Address Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Địa chỉ hiện tại:',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${originalProvince.isNotEmpty ? '$originalProvince, ' : ''}'
                            '${originalDistrict.isNotEmpty ? '$originalDistrict, ' : ''}'
                            '${originalCommune.isNotEmpty ? originalCommune : ''}',
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          color: const Color(0xFF8B5E3C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // New Address Section
                Text('Cập nhật địa chỉ mới (nếu cần)',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    color: const Color(0xFF8B5E3C),
                  ),
                ),
                const SizedBox(height: 8),

                // Province Dropdown
                _buildDropdown(
                  label: 'Chọn tỉnh/thành mới',
                  value: selectedProvince,
                  items: provinces,
                  onChanged: (value) {
                    setState(() => selectedProvince = value);
                    _loadDistricts(value['idProvince']);
                  },
                  isLoading: isProvincesLoading,
                ),
                const SizedBox(height: 16),

                // District Dropdown
                _buildDropdown(
                  label: 'Chọn quận/huyện mới',
                  value: selectedDistrict,
                  items: districts,
                  onChanged: (value) {
                    setState(() => selectedDistrict = value);
                    _loadCommunes(value['idDistrict']);
                  },
                  isLoading: isDistrictsLoading,
                ),
                const SizedBox(height: 16),

                // Commune Dropdown
                _buildDropdown(
                  label: 'Chọn phường/xã mới',
                  value: selectedCommune,
                  items: communes,
                  onChanged: (value) => setState(() => selectedCommune = value),
                  isLoading: isCommunesLoading,
                ),
                const SizedBox(height: 16),

                // New Address
                _buildTextField(
                  controller: addressController,
                  label: 'Địa chỉ cụ thể mới',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),

                // Experience Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    value: experience,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: Text('Chọn kinh nghiệm', style: GoogleFonts.lora(color: const Color(0xFF8B5E3C))),
                    items: const [
                      DropdownMenuItem(value: 'Có kinh nghiệm', child: Text('Có kinh nghiệm')),
                      DropdownMenuItem(value: 'Không có kinh nghiệm', child: Text('Không có kinh nghiệm')),
                    ],
                    onChanged: (value) => setState(() => experience = value),
                  ),
                ),
                const SizedBox(height: 16),

                // Experience Description
                _buildTextField(
                  controller: experienceDescriptionController,
                  label: 'Mô tả kinh nghiệm (tối đa 200 ký tự)',
                  icon: Icons.description,
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 16),

                // Bio
                _buildTextField(
                  controller: bioController,
                  label: 'Giới thiệu bản thân (tối đa 100 ký tự)',
                  icon: Icons.info,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Image Upload
                Text('Hình ảnh (tối đa 5 ảnh)', style: GoogleFonts.lora(fontSize: 16)),
                const SizedBox(height: 8),
                _buildImageGrid(),
                const SizedBox(height: 20),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleUpdateTechnician,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFD4A373),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        : Text('Cập nhật thông tin', style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => context.go('/home-technician'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: Text('Hủy bỏ', style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8B5E3C)),
        labelStyle: GoogleFonts.lora(color: const Color(0xFF8B5E3C), fontSize: 16),
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

  @override
  void dispose() {
    fullnameController.dispose();
    addressController.dispose();
    experienceDescriptionController.dispose();
    bioController.dispose();
    super.dispose();
  }
}