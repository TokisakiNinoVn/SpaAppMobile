import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/tinhthanh_service_v2.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';

class CreateTechnicianScreen extends StatefulWidget {
  const CreateTechnicianScreen({super.key});

  @override
  State<CreateTechnicianScreen> createState() => _CreateTechnicianScreen();
}

class _CreateTechnicianScreen extends State<CreateTechnicianScreen> {
  final fullnameController = TextEditingController();
  final addressController = TextEditingController();
  final technicianService = TechnicianService();
  final tinhThanhService = TinhThanhService();
  final fileService = FileService();

  bool isLoading = false;
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  dynamic selectedProvince;
  List<dynamic> selectedDistricts = [];
  String? selectedYear;
  String? experience;
  List<Map<String, dynamic>> images = [];
  Map<String, dynamic>? avatarImage;

  // Track uploaded file IDs for cleanup
  List<String> _uploadedImageIds = [];
  String? _uploadedAvatarId;

  final _provinceSearchController = TextEditingController();
  final _districtSearchController = TextEditingController();

  List<dynamic> filteredProvinces = [];
  List<dynamic> filteredDistricts = [];

  bool isProvincesLoading = false;
  bool isDistrictsLoading = false;

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
    fullnameController.dispose();
    addressController.dispose();
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
      if (listTinhThanh.isEmpty) {
        SnackBarHelper.showError(context, 'Không thể tải danh sách tỉnh thành');
      } else {
        setState(() {
          provinces = listTinhThanh;
          filteredProvinces = provinces;
        });
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi tải tỉnh thành: $e');
    } finally {
      setState(() => isProvincesLoading = false);
    }
  }

  Future<void> _loadDistricts(int idProvince) async {
    setState(() {
      isDistrictsLoading = true;
      districts = [];
      filteredDistricts = [];
      selectedDistricts.clear();
    });

    try {
      final listQuanHuyen = await tinhThanhService.getHuyenByTinh(idProvince);
      if (listQuanHuyen.isEmpty) {
        SnackBarHelper.showError(context, 'Không thể tải danh sách huyện');
      } else {
        setState(() {
          districts = listQuanHuyen;
          filteredDistricts = districts;
        });
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi tải huyện: $e');
    } finally {
      setState(() => isDistrictsLoading = false);
    }
  }

  // Clean up uploaded images
  Future<void> _cleanupUploadedImages() async {
    bool hasErrors = false;

    // Delete avatar if uploaded
    if (_uploadedAvatarId != null) {
      try {
        await fileService.deleteFileService(_uploadedAvatarId!);
        appLog('Deleted avatar: $_uploadedAvatarId');
      } catch (e) {
        appLog('Error deleting avatar: $e');
        hasErrors = true;
      }
    }

    // Delete all uploaded images
    for (final imageId in _uploadedImageIds) {
      try {
        await fileService.deleteFileService(imageId);
        appLog('Deleted image: $imageId');
      } catch (e) {
        appLog('Error deleting image $imageId: $e');
        hasErrors = true;
      }
    }

    if (!hasErrors && mounted) {
      SnackBarHelper.showSuccess(context, 'Đã xóa các ảnh đã tải lên');
    }
  }

  Future<void> handleCreateTechnician() async {
    final fullname = fullnameController.text.trim();
    final address = addressController.text.trim();

    if (fullname.isEmpty) {
      SnackBarHelper.showWarning(context, 'Vui lòng nhập họ tên');
      return;
    }
    if (selectedProvince == null || selectedDistricts.isEmpty) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn đầy đủ địa chỉ');
      return;
    }
    if (address.isEmpty) {
      SnackBarHelper.showWarning(context, 'Vui lòng nhập địa chỉ nơi ở');
      return;
    }
    if (selectedYear == null) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn năm sinh');
      return;
    }
    if (experience == null) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn kinh nghiệm');
      return;
    }
    if (images.length < 3) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn tối thiểu 3 ảnh');
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
        'images': images,
      };

      final response = await technicianService.createTechnicianService(data);
      if (response['success'] == true) {
        // Clear tracking as profile was created successfully
        _uploadedImageIds.clear();
        _uploadedAvatarId = null;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Hồ sơ đã tạo thành công, chờ duyệt'),
                ],
              ),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          context.go('/login');
        }
      } else {
        SnackBarHelper.showError(context, response['message'] ?? 'Có lỗi xảy ra khi tạo hồ sơ');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi hệ thống: $e');
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
            // Delete old avatar if exists
            if (_uploadedAvatarId != null) {
              fileService.deleteFileService(_uploadedAvatarId!);
            }
            avatarImage = imageData;
            _uploadedAvatarId = imageData['_id'];
          } else {
            images.add(imageData);
            _uploadedImageIds.add(imageData['_id']);
          }
        });
      } else {
        SnackBarHelper.showError(context, 'Không thể tải lên hình ảnh');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi tải lên hình ảnh: $e');
    }
  }

  Future<void> _pickImage({bool isAvatar = false}) async {
    if (!isAvatar && images.length >= 5) {
      SnackBarHelper.showError(context, 'Bạn chỉ được chọn tối đa 5 ảnh');
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
          toolbarColor: const Color(0xFF1A1A1A),
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

  Future<bool> _onWillPop() async {
    if (_uploadedImageIds.isNotEmpty || _uploadedAvatarId != null) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          title: const Text(
            'Xác nhận hủy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Bạn đã tải lên ảnh nhưng chưa tạo hồ sơ. Bạn có muốn hủy và xóa các ảnh đã tải lên không?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: const Text(
                'Ở lại',
                style: TextStyle(color: Color(0xFF666666)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 0,
              ),
              child: const Text('Hủy & Xóa ảnh'),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        await _cleanupUploadedImages();
        return true;
      }
      return false;
    }
    return true;
  }

  Future<void> deleteImage(String idImage, {bool isAvatar = false}) async {
    try {
      final response = await fileService.deleteFileService(idImage);

      if (response['status'] == 'success') {
        setState(() {
          if (isAvatar) {
            avatarImage = null;
            _uploadedAvatarId = null;
          } else {
            images.removeWhere((img) => img['_id'] == idImage);
            _uploadedImageIds.remove(idImage);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã xóa hình ảnh'),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        SnackBarHelper.showError(context, 'Không thể xóa hình ảnh');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi xóa hình ảnh: $e');
    }
  }

  void _showProvinceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) => _buildLocationBottomSheet(
        title: 'Chọn tỉnh/thành phố',
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
      SnackBarHelper.showWarning(context, 'Vui lòng chọn tỉnh/thành phố trước');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Chọn quận/huyện',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _districtSearchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF999999), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          district['name'],
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
                          ),
                        ),
                        value: isSelected,
                        activeColor: const Color(0xFF1A1A1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
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
                      elevation: 0,
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ),
                const SizedBox(height: 20),
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
      '6 năm', '7 năm', '8 năm', '9 năm', '10 năm', 'Trên 10 năm'
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn kinh nghiệm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: experiences.length,
                itemBuilder: (context, index) {
                  final exp = experiences[index];
                  return ListTile(
                    title: Text(exp),
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
    );
  }

  void _showYearBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) => Container(
        height: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Chọn năm sinh',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
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
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF999999), size: 20),
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: const Icon(Icons.add_a_photo, size: 32, color: Color(0xFF999999)),
            ),
          );
        }

        final image = images[index];
        return Stack(
          children: [
            GestureDetector(
              onTap: () => FullScreenSingleImageViewer(imageUrl: image['url']),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  FormatHelper.formatNetworkImageUrl(image['url']),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => deleteImage(image['_id']),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE74C3C),
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

  Widget _buildAvatarSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (avatarImage != null) {
              FullScreenSingleImageViewer(imageUrl: avatarImage!['url']);
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
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                ),
                child: ClipOval(
                  child: avatarImage != null
                      ? Image.network(
                    FormatHelper.formatNetworkImageUrl(avatarImage!['url']),
                    fit: BoxFit.cover,
                    width: 96,
                    height: 96,
                  )
                      : const Icon(Icons.person, size: 50, color: Color(0xFF999999)),
                ),
              ),
              if (avatarImage != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      if (_uploadedAvatarId != null) {
                        deleteImage(_uploadedAvatarId!, isAvatar: true);
                      } else {
                        setState(() {
                          avatarImage = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE74C3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _pickImage(isAvatar: true),
          icon: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF1A1A1A)),
          label: const Text(
            'Chọn ảnh đại diện',
            style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
          ),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: value != null ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
                  fontSize: 14,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF999999)),
              )
            else
              const Icon(Icons.arrow_drop_down, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop) {
                        context.go('/login');
                      }
                    },
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
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),

                Text(
                  'Tạo hồ sơ kỹ thuật viên',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ColorConfig.primary,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Hoàn tất hồ sơ để trở thành đối tác',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 20),

                _buildAvatarSection(),

                _buildTextField(
                  controller: fullnameController,
                  label: 'Họ và tên',
                  hint: 'Nguyễn Văn A',
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tỉnh/Thành phố',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildLocationField(
                            label: 'Chọn tỉnh/thành phố',
                            value: selectedProvince?['name'],
                            onTap: _showProvinceBottomSheet,
                            isLoading: isProvincesLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quận/Huyện',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 6),
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
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Address field
                _buildTextField(
                  controller: addressController,
                  label: 'Địa chỉ nơi ở',
                  hint: 'Số nhà, đường, khu phố...',
                ),

                const SizedBox(height: 16),

                // Year and Experience row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Năm sinh',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildLocationField(
                            label: 'Chọn năm sinh',
                            value: selectedYear,
                            onTap: _showYearBottomSheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kinh nghiệm',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildLocationField(
                            label: 'Chọn kinh nghiệm',
                            value: experience,
                            onTap: _showExperienceBottomSheet,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Images section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hình ảnh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      '${images.length}/5',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _buildImageGrid(),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () async {
                          final shouldPop = await _onWillPop();
                          if (shouldPop) {
                            context.go('/login');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleCreateTechnician,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: ColorConfig.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Tạo hồ sơ'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: BorderSide(color: ColorConfig.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        ),
      ],
    );
  }
}