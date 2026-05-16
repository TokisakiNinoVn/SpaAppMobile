import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/screens/widgets/date_of_birth_picker_bottom_sheet.dart';
import 'package:spa_app/screens/widgets/district_picker_bottom_sheet.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/service_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/tinhthanh_service_v2.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/utils/file_util.dart';

class UserEditTechnicianScreen extends StatefulWidget {
  const UserEditTechnicianScreen({super.key});

  @override
  State<UserEditTechnicianScreen> createState() => _UserEditTechnicianScreenState();
}

class _UserEditTechnicianScreenState extends State<UserEditTechnicianScreen> {
  final UserService userService = UserService();
  final ServiceService _serviceService = ServiceService();
  final FileUtils _fileUtils = FileUtils();

  final fullnameController = TextEditingController();
  final addressController = TextEditingController();
  final technicianService = TechnicianService();
  final tinhThanhService = TinhThanhService();
  final _serviceSearchController = TextEditingController();

  bool isLoading = false;
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> selectedDistricts = [];
  dynamic selectedProvince;
  String? experience;
  List<Map<String, dynamic>> images = [];
  Map<String, dynamic>? avatarImage;
  Map<String, dynamic>? dataUser;
  Map<String, dynamic>? technicianData;
  String selectedGender = 'female';
  final genders = ['male', 'female', 'other'];
  final Map<String, String> genderLabels = {
    'male': 'Nam',
    'female': 'Nữ',
    'other': 'Khác'
  };
  DateTime? selectedDate;

  bool isProvincesLoading = false;
  bool isDistrictsLoading = false;

  late String originalProvince;
  late List<String> originalDistricts;
  late String originalAddress;

  final experiences = ['1 năm', '2 năm', '3 năm', '4 năm', '5 năm', '6 năm', '7 năm'];

  List<dynamic> selectedServiceIds = [];
  List<dynamic>? allServices = [];
  List<dynamic> filteredServices = [];

  // Store existing service IDs from API
  List<String> _existingServiceIds = [];

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

  Future<void> _loadAllServices() async {
    try {
      final response = await _serviceService.listService();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          allServices = response['data'];
          filteredServices = List.from(allServices ?? []);

          // Khớp các service ID cũ với object service từ API
          if (_existingServiceIds.isNotEmpty && allServices != null) {
            selectedServiceIds = allServices!.where((service) {
              return _existingServiceIds.contains(service['_id']);
            }).toList();
          }
        });
      }
    } catch (e) {
      appLog("Error loading services: $e");
      SnackBarHelper.showError(context, 'Không thể tải danh sách dịch vụ');
    }
  }

  Future<void> _loadUserDetail() async {
    setState(() => isLoading = true);
    try {
      final response = await userService.loadDetailUserService();
      // appLog("User detail response: $response");

      if (response['success'] == true) {
        setState(() {
          dataUser = response['data'];
          technicianData = response['data']['technician'];
          appLog("Technician data: $technicianData");
          _initializeData();
        });
        await _loadProvinces();
        await _loadAllServices();
      } else {
        _showSnack(response['message'] ?? 'Không thể tải thông tin người dùng');
      }
    } catch (e) {
      appLog("Error loading user detail: $e");
      _showSnack('Lỗi tải thông tin: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _initializeData() {
    if (technicianData == null) return;

    fullnameController.text = technicianData?['fullName'] ?? '';
    addressController.text = technicianData?['address'] ?? '';
    experience = technicianData?['experience'] ?? '1 năm';
    // yearOfBirth = technicianData?['yearOfBirth'];
    // selectedDate = technicianData?['selectedDate'];
    if (technicianData?['dateOfBirth'] != null) {
      selectedDate = DateTime.parse(technicianData!['dateOfBirth']).toLocal();
      appLog("Select date: $selectedDate");
    } else {
      appLog("technicianData!['dateOfBirth']: ${technicianData!['dateOfBirth']}");
      selectedDate = null;
    }

    // Parse gender from technician data or user data
    if (technicianData?['gender'] != null) {
      selectedGender = technicianData!['gender'];
    }

    originalProvince = technicianData?['province'] ?? '';
    originalDistricts = List<String>.from(technicianData?['districts'] ?? []);
    originalAddress = technicianData?['address'] ?? '';

    // Parse existing service IDs
    if (technicianData?['serviceIds'] != null) {
      _existingServiceIds = List<String>.from(technicianData!['serviceIds']);
    }

    // Parse avatar
    if (technicianData?['avatar'] != null && technicianData!['avatar']['url'] != null) {
      avatarImage = {
        '_id': technicianData!['avatar']['_id'] ?? '',
        'url': technicianData!['avatar']['url'],
        'uploadedAt': technicianData!['avatar']['uploadedAt'] ?? DateTime.now().toIso8601String()
      };
    }

    // Parse images
    if (technicianData?['images'] != null && technicianData!['images'].isNotEmpty) {
      images = List<Map<String, dynamic>>.from(technicianData!['images'].map((img) => {
        '_id': img['_id'] ?? '',
        'url': img['url'],
        'uploadedAt': img['uploadedAt'] ?? img['createdAt'] ?? DateTime.now().toIso8601String()
      })).toList();
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

          // Tìm tỉnh hiện tại từ dữ liệu người dùng
          if (technicianData?['province'] != null && technicianData!['province'].isNotEmpty) {
            try {
              selectedProvince = provinces.firstWhere(
                    (prov) => prov['name'] == technicianData!['province'],
              );
              if (selectedProvince != null) {
                _loadDistricts(selectedProvince['id']);
              }
            } catch (e) {
              appLog("Province not found: ${technicianData!['province']}");
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
        SnackBarHelper.showError(context, 'Không thể tải danh sách quận/huyện');
      } else {
        setState(() {
          districts = listQuanHuyen;

          if (technicianData?['districts'] != null && technicianData!['districts'].isNotEmpty) {
            selectedDistricts = districts.where((district) =>
                technicianData!['districts'].contains(district['name'])
            ).toList();
          }
        });
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi tải quận/huyện: $e');
    } finally {
      setState(() => isDistrictsLoading = false);
    }
  }

  Future<void> handleUpdateTechnician() async {
    if (technicianData == null) return;

    final fullname = fullnameController.text.trim();
    final address = addressController.text.trim();
    if (avatarImage == null) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn ảnh đại diện');
      return;
    }
    if (selectedDate == null) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn ngày sinh');
      return;
    }
    final age = DateTime.now().difference(selectedDate!).inDays ~/ 365;
    if (age < 18) {
      SnackBarHelper.showWarning(context, 'Bạn phải từ đủ 18 tuổi trở lên để đăng ký');
      return;
    }
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

      // Extract service IDs from selected services
      final serviceIdList = selectedServiceIds.map((service) => service['_id']).toList();

      final data = {
        'fullName': fullname,
        'province': province,
        'districts': districtsList,
        'address': address,
        'experience': experience,
        'gender': selectedGender,
        'dateOfBirth': selectedDate?.toUtc().toIso8601String(),

        // 'serviceIds': serviceIdList,
      };

      // Only include avatar if it exists and has an ID or is new
      if (avatarImage != null && avatarImage!['url'] != null) {
        data['avatar'] = avatarImage;
      }

      // Only include images if they exist
      if (images.isNotEmpty) {
        data['images'] = images;
      }

      appLog("Updating technician with data: $data");

      final response = await technicianService.updateTechnicianService(technicianData!['_id'], data);
      appLog("Update response: $response");

      if (response['success'] == true) {
        _showSnack('Cập nhật hồ sơ thành công', isError: false);
        context.pop(true);
      } else {
        _showSnack(response['message'] ?? 'Có lỗi xảy ra khi cập nhật hồ sơ');
      }
    } catch (e) {
      appLog("Error updating technician: $e");
      _showSnack('Lỗi hệ thống: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> uploadImage(String filePath, {bool isAvatar = false}) async {
    try {
      final uploadService = UploadService();
      final response = await uploadService.uploadSingleFileService(filePath);

      if (response['success'] == true && response['data'] != null) {
        final imageData = response['data'];
        setState(() {
          if (isAvatar) {
            avatarImage = {
              '_id': imageData['_id'],
              'url': imageData['url'],
              'uploadedAt': imageData['uploadedAt'] ?? DateTime.now().toIso8601String()
            };
          } else {
            images.add({
              '_id': imageData['_id'],
              'url': imageData['url'],
              'uploadedAt': imageData['uploadedAt'] ?? DateTime.now().toIso8601String()
            });
          }
        });
        _showSnack('Tải ảnh lên thành công', isError: false);
      } else {
        _showSnack(response['message'] ?? 'Không thể tải lên hình ảnh');
      }
    } catch (e) {
      appLog("Error uploading image: $e");
      _showSnack('Lỗi tải lên hình ảnh: $e');
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
      // Tỉ lệ crop: avatar 1:1, ảnh thường 16:9
      final double ratioX = isAvatar ? 1.0 : 1.0;
      final double ratioY = isAvatar ? 1.0 : 1.0;
      final File? croppedImage = await _fileUtils.cropImage(
        File(pickedFile.path),
        ratioX,
        ratioY,
      );
      if (croppedImage != null) {
        await uploadImage(croppedImage.path, isAvatar: isAvatar);
      } else {
        SnackBarHelper.showWarning(context, 'Đã hủy cắt ảnh');
      }
    }
  }

  // Future<void> _pickImage({bool isAvatar = false}) async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //
  //   if (pickedFile != null) {
  //     await _cropImage(File(pickedFile.path), isAvatar: isAvatar);
  //   }
  // }

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
        setState(() {
          images.removeWhere((img) => img['_id'] == idImage);
        });
        _showSnack('Hình ảnh đã được xóa', isError: false);
      } else {
        _showSnack('Không thể xóa hình ảnh');
      }
    } catch (e) {
      appLog("Error deleting image: $e");
      _showSnack('Lỗi xóa hình ảnh: $e');
    }
  }

  Future<void> deleteAvatar() async {
    if (avatarImage != null && avatarImage!['_id'] != null) {
      try {
        final fileService = FileService();
        await fileService.deleteFileService(avatarImage!['_id']);
        setState(() {
          avatarImage = null;
        });
        _showSnack('Ảnh đại diện đã được xóa', isError: false);
      } catch (e) {
        appLog("Error deleting avatar: $e");
        _showSnack('Lỗi xóa ảnh đại diện: $e');
      }
    } else {
      setState(() {
        avatarImage = null;
      });
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  FormatHelper.formatNetworkImageUrl(imageUrl),
                  fit: BoxFit.contain,
                ),
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
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getExperienceDisplayText() {
    if (experience == null) return 'Chọn kinh nghiệm';
    return experience!;
  }

  String _getServicesDisplayText() {
    if (selectedServiceIds.isEmpty) return 'Chọn dịch vụ';
    if (selectedServiceIds.length == 1) {
      return selectedServiceIds[0]['name'];
    }
    return '${selectedServiceIds.length} dịch vụ';
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
                style: TextStyle(
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBottomSheetHandle(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Chọn Tỉnh/Thành",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              ),
            );
          },
        );
      },
    );
  }

  // void _showDistrictBottomSheet() {
  //   if (selectedProvince == null) {
  //     _showSnack('Vui lòng chọn tỉnh/thành trước');
  //     return;
  //   }
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context, setModalState) {
  //           return Container(
  //             padding: const EdgeInsets.only(bottom: 20),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 _buildBottomSheetHandle(),
  //                 const Padding(
  //                   padding: EdgeInsets.all(16.0),
  //                   child: Text(
  //                     "Chọn Quận/Huyện",
  //                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                   ),
  //                 ),
  //                 Expanded(
  //                   child: ListView.builder(
  //                     itemCount: districts.length,
  //                     itemBuilder: (context, index) {
  //                       final district = districts[index];
  //                       final isSelected = selectedDistricts.any((d) => d['id'] == district['id']);
  //
  //                       return CheckboxListTile(
  //                         title: Text(district['name']),
  //                         value: isSelected,
  //                         activeColor: const Color(0xFF8B5E3C),
  //                         onChanged: (bool? value) {
  //                           setModalState(() {
  //                             if (value == true) {
  //                               selectedDistricts.add(district);
  //                             } else {
  //                               selectedDistricts.removeWhere((d) => d['id'] == district['id']);
  //                             }
  //                           });
  //                           setState(() {});
  //                         },
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 Padding(
  //                   padding: const EdgeInsets.all(16.0),
  //                   child: SizedBox(
  //                     width: double.infinity,
  //                     child: ElevatedButton(
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: const Color(0xFF8B5E3C),
  //                         foregroundColor: Colors.white,
  //                         padding: const EdgeInsets.symmetric(vertical: 14),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(40),
  //                         ),
  //                       ),
  //                       child: const Text('Xác nhận', style: TextStyle(fontSize: 16)),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void _showDistrictBottomSheet() async {
    if (selectedProvince == null) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn tỉnh/thành phố trước');
      return;
    }

    // Chuyển districts (List<dynamic>) thành List<District>
    final districtList = districts.map((d) => District.fromJson(d)).toList();

    // Lấy danh sách id đã chọn từ selectedDistricts
    final Set<int> selectedIds = selectedDistricts.map((d) => d['id'] as int).toSet();

    // Chọn đúng các đối tượng District từ districtList dựa trên id
    final initialSelectedList = districtList.where((d) => selectedIds.contains(d.id)).toList();

    final result = await showDistrictPickerBottomSheet(
      context: context,
      districts: districtList,
      initialSelected: initialSelectedList,
    );

    if (result != null) {
      setState(() {
        selectedDistricts = result.map((d) => d.rawData ?? d.toJson()).toList();
      });
    }
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

  void _showServicesBottomSheet() {
    if (allServices == null || allServices!.isEmpty) {
      _showSnack('Đang tải danh sách dịch vụ...');
      return;
    }

    _serviceSearchController.clear();
    setState(() {
      filteredServices = List.from(allServices!);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
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
                    setModalState(() {
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
                Flexible(
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
                    shrinkWrap: true,
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
                          setModalState(() {
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
          );
        },
      ),
    );
  }

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
            onTap: () => _pickImage(isAvatar: false),
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
                  FormatHelper.formatNetworkImageUrl(image['url']),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, color: Colors.red),
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
                  border: Border.all(color: ColorConfig.primary, width: 2),
                ),
                child: ClipOval(
                  child: avatarImage != null && avatarImage!['url'] != null
                      ? Image.network(
                    FormatHelper.formatNetworkImageUrl(avatarImage!['url']),
                    fit: BoxFit.cover,
                    width: 90,
                    height: 90,
                    loadingBuilder: (context, child, progress) {
                      return progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 50, color: Colors.grey);
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
                    onTap: deleteAvatar,
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
            backgroundColor: ColorConfig.primary,
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
    if (isLoading && technicianData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConfig.white,
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
            const Text(
              "Cập nhật hồ sơ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        color: ColorConfig.white,
        width: double.infinity,
        height: double.infinity,
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
                ),
                const SizedBox(height: 16),

                _buildGenderSection(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Năm sinh',
                            style: TextStyle(
                              color: ColorConfig.textBlack,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // _buildSelectionField(
                          //   label: 'Chọn năm sinh',
                          //   value: _getYearOfBirthDisplayText(),
                          //   onTap: _showYearOfBirthBottomSheet,
                          // ),
                          _buildLocationField(
                            label: 'Chọn ngày sinh',
                            value: selectedDate != null
                                ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                : null,
                            onTap: () async {
                              final currentDate = DateTime.now();
                              final minDate = DateTime(currentDate.year - 100, currentDate.month, currentDate.day);
                              final maxDate = DateTime(currentDate.year - 18, currentDate.month, currentDate.day);

                              final picked = await showDateOfBirthPickerBottomSheet(
                                context: context,
                                initialDate: selectedDate ?? maxDate,
                                minimumDate: minDate,
                                maximumDate: maxDate,
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
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
                            style: TextStyle(
                              color: ColorConfig.textBlack,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildSelectionField(
                            label: 'Chọn kinh nghiệm',
                            value: _getExperienceDisplayText(),
                            onTap: _showExperienceBottomSheet,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

                // Địa chỉ cụ thể
                // _buildTextField(
                //   controller: addressController,
                //   label: 'Địa chỉ cụ thể',
                //   icon: Icons.location_on,
                // ),

                _buildTextField(
                  controller: addressController,
                  label: 'Địa chỉ cụ thể *',
                  hint: 'Số nhà, tên đường, thôn/xóm...',
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // _buildSectionTitle('Dịch vụ cung cấp'),
                // _buildSelectionField(
                //   label: 'Chọn dịch vụ',
                //   value: _getServicesDisplayText(),
                //   onTap: _showServicesBottomSheet,
                // ),
                // const SizedBox(height: 16),

                // Hình ảnh
                const Text('Hình ảnh (3-5 ảnh)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8B5E3C),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: const Text('Hủy bỏ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleUpdateTechnician,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: ColorConfig.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            : const Text('Cập nhật', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildGenderSection() {
    final genderOptions = [
      {'value': 'male', 'label': 'Nam', 'icon': Icons.male},
      {'value': 'female', 'label': 'Nữ', 'icon': Icons.female},
      {'value': 'other', 'label': 'Khác', 'icon': Icons.person},
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

  @override
  void dispose() {
    fullnameController.dispose();
    addressController.dispose();
    _serviceSearchController.dispose();
    super.dispose();
  }
}