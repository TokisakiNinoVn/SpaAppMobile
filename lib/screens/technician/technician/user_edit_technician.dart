import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/tinhthanh_service_v2.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';

class UserEditTechnicianScreen extends StatefulWidget {
  const UserEditTechnicianScreen({super.key});

  @override
  State<UserEditTechnicianScreen> createState() => _UserEditTechnicianScreenState();
}

class _UserEditTechnicianScreenState extends State<UserEditTechnicianScreen> {
  final UserService userService = UserService();
  final fullnameController = TextEditingController();
  final addressController = TextEditingController();
  final bioController = TextEditingController();
  final technicianService = TechnicianService();
  final tinhThanhService = TinhThanhService();

  bool isLoading = false;
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> filteredProvinces = [];
  List<dynamic> filteredDistricts = [];
  List<dynamic> selectedDistricts = [];
  dynamic selectedProvince;
  dynamic selectedDistrict;
  String? experience;
  List<Map<String, dynamic>> images = [];
  Map<String, dynamic>? avatarImage;
  Map<String, dynamic>? dataUser;
  Map<String, dynamic>? technicianData;

  bool isProvincesLoading = false;
  bool isDistrictsLoading = false;

  late String originalProvince;
  late List<String> originalDistricts;
  late String originalAddress;

  List<String> services = [];
  List<String> availableServices = ['Đá nóng', 'Giác hơi', 'Cạo gió'];
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
    '10 năm',
  ];

  // Danh sách năm sinh từ 1950 đến năm hiện tại - 18
  List<int> get birthYears {
    final currentYear = DateTime.now().year;
    return List<int>.generate(currentYear - 1950 - 17, (index) => currentYear - 18 - index);
  }

  int? yearOfBirth;

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

    fullnameController.text = technicianData?['fullName'] ?? '';
    addressController.text = technicianData?['address'] ?? '';
    bioController.text = technicianData?['bio'] ?? '';
    experience = technicianData?['experience'] ?? '1 năm';
    yearOfBirth = technicianData?['yearOfBirth'];
    services = List<String>.from(technicianData?['services'] ?? []);

    originalProvince = technicianData?['province'] ?? '';
    originalDistricts = List<String>.from(technicianData?['districts'] ?? []);
    originalAddress = technicianData?['address'] ?? '';

    if (technicianData?['avatar'] != null) {
      avatarImage = {
        '_id': technicianData!['avatar']['_id'],
        'url': technicianData!['avatar']['url'],
        'createdAt': technicianData!['avatar']['uploadedAt'] ?? technicianData!['avatar']['createdAt']
      };
    }

    if (technicianData?['images'] != null && technicianData!['images'].isNotEmpty) {
      images = List<Map<String, dynamic>>.from(technicianData!['images'].map((img) => {
        '_id': img['_id'],
        'url': img['url'],
        'createdAt': img['uploadedAt'] ?? img['createdAt']
      })).toList();
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => isProvincesLoading = true);
    try {
      final listTinhThanh = await tinhThanhService.getTinhThanh();
      if (listTinhThanh.isEmpty) {
        SnackbarHelper.showError(context, 'Không thể tải danh sách tỉnh thành');
      } else {
        setState(() {
          provinces = listTinhThanh;
          filteredProvinces = provinces;

          // Tìm tỉnh hiện tại từ dữ liệu người dùng
          if (technicianData?['province'] != null) {
            selectedProvince = provinces.firstWhere(
                  (prov) => prov['name'] == technicianData!['province'],
            );
            if (selectedProvince != null) {
              _loadDistricts(selectedProvince['id']);
            }
          }
        });
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Lỗi tải tỉnh thành: $e');
    } finally {
      setState(() => isProvincesLoading = false);
    }
  }

  Future<void> _loadDistricts(int idProvince) async {
    setState(() => isDistrictsLoading = true);
    try {
      final listQuanHuyen = await tinhThanhService.getHuyenByTinh(idProvince);
      if (listQuanHuyen.isEmpty) {
        SnackbarHelper.showError(context, 'Không thể tải danh sách huyện');
      } else {
        setState(() {
          districts = listQuanHuyen;
          filteredDistricts = districts;

          if (technicianData?['districts'] != null && technicianData!['districts'].isNotEmpty) {
            selectedDistricts = districts.where((district) =>
                technicianData!['districts'].contains(district['name'])
            ).toList();
          }
        });
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Lỗi tải huyện: $e');
    } finally {
      setState(() => isDistrictsLoading = false);
    }
  }

  Future<void> handleUpdateTechnician() async {
    if (technicianData == null) return;

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
    if (experience == null) {
      _showSnack('Vui lòng chọn kinh nghiệm');
      return;
    }
    if (selectedDistricts.isEmpty) {
      _showSnack('Vui lòng chọn ít nhất một quận/huyện');
      return;
    }
    if (images.length < 3) {
      _showSnack('Vui lòng tải lên ít nhất 3 hình ảnh');
      return;
    }

    setState(() => isLoading = true);

    try {
      final province = selectedProvince != null ? selectedProvince['name'] : originalProvince;
      final districtsList = selectedDistricts.isNotEmpty
          ? selectedDistricts.map((d) => d['name']).toList()
          : originalDistricts;

      final data = {
        'avatar': avatarImage != null ? avatarImage : null,
        'fullName': fullname,
        'province': province,
        'districts': districtsList,
        'address': address,
        'experience': experience,
        'images': images.toList(),
        'bio': bio,
        'services': services,
        'yearOfBirth': yearOfBirth,
      };

      final response = await technicianService.updateTechnicianService(technicianData!['_id'], data);
      debugPrint("response: $response");
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
      // Luôn cắt ảnh dù là avatar hay ảnh thường
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

  String _getDistrictsDisplayText() {
    if (selectedDistricts.isEmpty) return 'Chọn quận/huyện';

    final districtNames = selectedDistricts.map((d) => d['name']).toList();
    final displayText = districtNames.join(', ');

    // Giới hạn độ dài hiển thị
    if (displayText.length > 30) {
      return '${displayText.substring(0, 27)}...';
    }

    return displayText;
  }

  String _getProvinceDisplayText() {
    if (selectedProvince == null) return 'Chọn tỉnh/thành';
    return selectedProvince['name'];
  }

  String _getYearOfBirthDisplayText() {
    if (yearOfBirth == null) return 'Năm sinh';
    return yearOfBirth.toString();
  }

  String _getExperienceDisplayText() {
    if (experience == null) return 'Kinh nghiệm';
    return experience!;
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.lora(
                  color: value != label ? Colors.black87 : const Color(0xFF8B5E3C),
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.arrow_drop_down, color: Color(0xFF8B5E3C)),
          ],
        ),
      ),
    );
  }

  void _showProvinceBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Chọn Tỉnh/Thành",
                style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provinces.length,
                itemBuilder: (context, index) {
                  final province = provinces[index];
                  final isSelected = selectedProvince != null && selectedProvince['id'] == province['id'];

                  return ListTile(
                    title: Text(province['name']),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF8B5E3C)) : null,
                    onTap: () {
                      setState(() {
                        selectedProvince = province;
                        selectedDistricts.clear();
                        _loadDistricts(province['id']);
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDistrictBottomSheet() {
    if (selectedProvince == null) {
      _showSnack('Vui lòng chọn tỉnh/thành trước');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Chọn Quận/Huyện",
                    style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: districts.length,
                    itemBuilder: (context, index) {
                      final district = districts[index];
                      final isSelected = selectedDistricts.any((d) => d['id'] == district['id']);

                      return CheckboxListTile(
                        title: Text(district['name']),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              selectedDistricts.add(district);
                            } else {
                              selectedDistricts.removeWhere((d) => d['id'] == district['id']);
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5E3C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showYearOfBirthBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Chọn Năm Sinh",
                style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: birthYears.length,
                itemBuilder: (context, index) {
                  final year = birthYears[index];
                  final isSelected = yearOfBirth == year;

                  return ListTile(
                    title: Text(year.toString()),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF8B5E3C)) : null,
                    onTap: () {
                      setState(() {
                        yearOfBirth = year;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExperienceBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Chọn Kinh Nghiệm",
                style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: experiences.length,
                itemBuilder: (context, index) {
                  final exp = experiences[index];
                  final isSelected = experience == exp;

                  return ListTile(
                    title: Text(exp),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF8B5E3C)) : null,
                    onTap: () {
                      setState(() {
                        experience = exp;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServicesMultiSelect() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dịch vụ cung cấp', style: GoogleFonts.lora(
            color: const Color(0xFF8B5E3C),
            fontSize: 16,
          )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableServices.map((service) {
              final isSelected = services.contains(service);
              return FilterChip(
                label: Text(service, style: GoogleFonts.lora()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      services.add(service);
                    } else {
                      services.remove(service);
                    }
                  });
                },
                selectedColor: const Color(0xFFD4A373),
                checkmarkColor: Colors.white,
                backgroundColor: Colors.grey[200],
              );
            }).toList(),
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4A373), width: 2),
                ),
                child: ClipOval(
                  child: avatarImage != null
                      ? Image.network(
                    FormatHelper.formatImageUrl(avatarImage!['url']),
                    fit: BoxFit.cover,
                    width: 90,
                    height: 90,
                    loadingBuilder: (context, child, progress) {
                      return progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator());
                    },
                  )
                      : const Icon(Icons.person, size: 50, color: Colors.grey),
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
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _pickImage(isAvatar: true),
          icon: const Icon(Icons.camera_alt, size: 18),
          label: const Text('Chọn ảnh đại diện', style: TextStyle(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4A373),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tỉnh/Thành',
                            style: ThemeConfig.appTextStyle(
                              color: ColorConfig.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildSelectionField(
                            label: 'Chọn tỉnh/thành',
                            value: _getProvinceDisplayText(),
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
                            'Quận/Huyện',
                            style: ThemeConfig.appTextStyle(
                              color: ColorConfig.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildSelectionField(
                            label: 'Chọn quận/huyện',
                            value: _getDistrictsDisplayText(),
                            onTap: _showDistrictBottomSheet,
                            isLoading: isDistrictsLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Địa chỉ cụ thể
                _buildTextField(
                  controller: addressController,
                  label: 'Địa chỉ cụ thể',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Năm sinh',
                            style: ThemeConfig.appTextStyle(
                              color: ColorConfig.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildSelectionField(
                            label: 'Năm sinh',
                            value: _getYearOfBirthDisplayText(),
                            onTap: _showYearOfBirthBottomSheet,
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
                            'Kinh nghiệm',
                            style: ThemeConfig.appTextStyle(
                              color: ColorConfig.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildSelectionField(
                            label: 'Kinh nghiệm',
                            value: _getExperienceDisplayText(),
                            onTap: _showExperienceBottomSheet,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dịch vụ
                _buildServicesMultiSelect(),
                const SizedBox(height: 16),

                // Giới thiệu bản thân
                _buildTextField(
                  controller: bioController,
                  label: 'Giới thiệu bản thân (tối đa 100 ký tự)',
                  icon: Icons.info,
                  maxLines: 3,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Hình ảnh
                Text('Hình ảnh (tối đa 5 ảnh, tối thiểu 3 ảnh)',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    color: const Color(0xFF8B5E3C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildImageGrid(),
                const SizedBox(height: 20),

                // Nút cập nhật và hủy trên cùng một dòng
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => context.go('/home-technician'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Hủy bỏ', style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleUpdateTechnician,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFD4A373),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            : Text('Cập nhật', style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8B5E3C)),
        labelStyle: GoogleFonts.lora(color: const Color(0xFF8B5E3C), fontSize: 16),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
    bioController.dispose();
    super.dispose();
  }
}