import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/fcm_helper.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/screens/components/required_label.dart';
import 'package:spa_app/screens/widgets/district_picker_bottom_sheet.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/tinhthanh_service_v2.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/service_service.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';
import 'package:spa_app/screens/widgets/date_of_birth_picker_bottom_sheet.dart';
import 'package:spa_app/utils/file_util.dart';
import '../../../storage/index.dart';

class CreateProfileTechnician extends StatefulWidget {
  const CreateProfileTechnician({super.key});

  @override
  State<CreateProfileTechnician> createState() => _CreateTechnicianScreen();
}

class _CreateTechnicianScreen extends State<CreateProfileTechnician> {
  final UploadService _uploadService = UploadService();
  final ServiceService _serviceService = ServiceService();

  final fullnameController = TextEditingController();
  final addressController = TextEditingController();
  final technicianService = TechnicianService();
  final tinhThanhService = TinhThanhService();
  final fileService = FileService();
  final FileUtils _fileUtils = FileUtils();

  bool isLoading = false;
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  dynamic selectedProvince;
  List<dynamic> selectedDistricts = [];
  String? experience;
  List<Map<String, dynamic>> images = [];
  Map<String, dynamic>? avatarImage;

  List<String> _uploadedImageIds = [];
  String? _uploadedAvatarId;
  String? fcmToken;

  DateTime? selectedDate;

  final _provinceSearchController = TextEditingController();
  final _districtSearchController = TextEditingController();
  final _serviceSearchController = TextEditingController();

  List<dynamic> filteredProvinces = [];
  List<dynamic> filteredDistricts = [];
  List<dynamic> filteredServices = [];
  List<dynamic> selectedServiceIds = [];
  List<dynamic>? allServices = [];

  // Gender: 'male' | 'female' | 'other'
  String selectedGender = 'male';

  bool isProvincesLoading = false;
  bool isDistrictsLoading = false;
  late final List<String> years;

  @override
  void initState() {
    super.initState();
    _provinceSearchController.addListener(_filterProvinces);
    _districtSearchController.addListener(_filterDistricts);
    _serviceSearchController.addListener(_filterServices);
    _loadProvinces();
    _loadAllServices();
    // _generateYearsList();
    _initFCM();
  }

  @override
  void dispose() {
    _provinceSearchController.dispose();
    _districtSearchController.dispose();
    _serviceSearchController.dispose();
    fullnameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _initFCM() async {
    final token = await FcmHelper.getFCMToken();

    if (token != null) {
      // appLog('FCM TOKEN: $token');
      fcmToken = token;
    }
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

  void _filterServices() {
    final query = _serviceSearchController.text.toLowerCase();
    setState(() {
      filteredServices = (allServices ?? []).where((service) {
        return service['name'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadAllServices() async {
    try {
      final response = await _serviceService.listService();
      setState(() {
        allServices = response['data'];
        filteredServices = allServices ?? [];
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

  Future<void> _cleanupUploadedImages() async {
    bool hasErrors = false;

    if (_uploadedAvatarId != null) {
      try {
        await fileService.deleteFileService(_uploadedAvatarId!);
        appLog('Deleted avatar: $_uploadedAvatarId');
      } catch (e) {
        appLog('Error deleting avatar: $e');
        hasErrors = true;
      }
    }

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
    if (avatarImage == null) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn ảnh đại diện');
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
    if (selectedDate == null) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn ngày sinh');
      return;
    }
    final age = DateTime.now().difference(selectedDate!).inDays ~/ 365;
    if (age < 18) {
      SnackBarHelper.showWarning(context, 'Bạn phải từ đủ 18 tuổi trở lên để đăng ký');
      return;
    }
    if (experience == null) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn kinh nghiệm');
      return;
    }
    if (selectedServiceIds.isEmpty) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn ít nhất 1 dịch vụ cung cấp');
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
        'dateOfBirth': selectedDate?.toUtc().toIso8601String(),
        'experience': experience,
        'images': images,
        'serviceIds': selectedServiceIds.map((s) => s['_id']).toList(),
        'gender': selectedGender,
        "fcm_token": fcmToken,
      };

      final response = await technicianService.createTechnicianService(data);
      appLog("Response create technician: $response");
      if (response['success'] == true) {
        _uploadedImageIds.clear();
        _uploadedAvatarId = null;

        if (mounted) {
          final isHaveTechnician = response['data']?['isHaveTechnician'] ?? false;

          if (isHaveTechnician) {
            await SharedPrefs.saveValue(PrefType.string, 'technician', response['data']?['technicianProfile']);
            await SharedPrefs.saveValue(PrefType.string, 'serviceIds', response['data']?['technicianProfile']['serviceIds'] ?? []);
            await SharedPrefs.saveValue(PrefType.string, 'inforService', response['data']?['inforService']);

            await SharedPrefs.saveValue(PrefType.bool, 'isHaveTechnician', true);

            SnackBarHelper.showSuccess(context, "Hồ sơ đã tạo thành công, chờ duyệt");
            context.pop();
          }

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
      final response = await _uploadService.uploadSingleFileService(filePath);
      final imageData = response['data'];

      if (imageData != null) {
        setState(() {
          if (isAvatar) {
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
      // Tỉ lệ crop: avatar 1:1, ảnh thường 16:9
      final double ratioX = isAvatar ? 1.0 : 1.0;
      final double ratioY = isAvatar ? 1.0 : 1.0;
      // final File? croppedImage = await _fileUtils.cropImage(
      //   File(pickedFile.path),
      //   ratioX,
      //   ratioY,
      // );

      final File? croppedImage = await _fileUtils.cropImage(
        context,
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
              child: const Text('Ở lại', style: TextStyle(color: Color(0xFF666666))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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

  // ── Bottom sheets ──────────────────────────────────────────────
  void _showProvinceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.5,
        child: _buildLocationBottomSheet(
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
      ),
    );
  }

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

  void _showServicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: StatefulBuilder(
          builder: (context, setStateModal) {
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
                  const Text(
                    'Dịch vụ cung cấp',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chọn các dịch vụ bạn có thể thực hiện',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  _buildSearchField(_serviceSearchController, 'Tìm kiếm dịch vụ'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredServices.isEmpty
                        ? Center(
                      child: Text(
                        'Không có dịch vụ nào',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    )
                        : ListView.builder(
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = filteredServices[index];
                        final isSelected = selectedServiceIds.any((s) => s['_id'] == service['_id']);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            service['name'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
                            ),
                          ),
                          value: isSelected,
                          activeColor: ColorConfig.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                          onChanged: (bool? value) {
                            setStateModal(() {
                              if (value == true) {
                                selectedServiceIds.add(service);
                              } else {
                                selectedServiceIds.removeWhere((s) => s['_id'] == service['_id']);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildConfirmButton(() => Navigator.pop(context)),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
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

  // void _showDateOfBirthBottomSheet() {
  //   final currentDate = DateTime.now();
  //   final minDate = DateTime(currentDate.year - 100, currentDate.month, currentDate.day);
  //   final maxDate = DateTime(currentDate.year - 18, currentDate.month, currentDate.day);
  //
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) => Container(
  //       height: 380,
  //       padding: const EdgeInsets.all(20),
  //       child: Column(
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               const Text(
  //                 'Chọn ngày sinh',
  //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 16),
  //           Expanded(
  //             child: CupertinoDatePicker(
  //               mode: CupertinoDatePickerMode.date,
  //               initialDateTime: selectedDate ?? maxDate,
  //               minimumDate: minDate,
  //               maximumDate: maxDate,
  //               onDateTimeChanged: (DateTime newDate) {
  //                 setState(() => selectedDate = newDate);
  //               },
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //           _buildConfirmButton(() => Navigator.pop(context)),
  //           const SizedBox(height: 10),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ── Shared helpers ─────────────────────────────────────────────
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

  Widget _buildSearchField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
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

  Widget _buildConfirmButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 16),
          _buildSearchField(controller, 'Tìm kiếm'),
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

  // ── Sections ───────────────────────────────────────────────────

  /// Radio button group for gender selection
  Widget _buildGenderSection() {
    final genderOptions = [
      {'value': 'male', 'label': 'Nam', 'icon': Icons.male_rounded},
      {'value': 'female', 'label': 'Nữ', 'icon': Icons.female_rounded},
      {'value': 'other', 'label': 'Khác', 'icon': Icons.person_outline_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   'Giới tính',
        //   style: TextStyle(fontSize: 14, color: ColorConfig.textBlack),
        // ),
        RequiredLabel(text: "Giới tính",),
        const SizedBox(height: 5),
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
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
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
                        setState(() => avatarImage = null);
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
        // const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _pickImage(isAvatar: true),
          icon: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF1A1A1A)),
          // label: const Text(
          //   'Chọn ảnh đại diện',
          //   style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
          // ),
          label: RequiredLabel(text: "Chọn ảnh đại diện"),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: ColorConfig.primaryBackground,
          elevation: 0,
          title: Row(
            children: [
              InkWell(
                // onTap: () => context.pop(),
                onTap: () async {
                  final shouldPop = await _onWillPop();
                  if (shouldPop) context.go('/login');
                },
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
              const SizedBox(width: 16),
              Text(
                'Tạo hồ sơ kỹ thuật viên',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: ColorConfig.black,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: ColorConfig.primaryBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Column(
              children: [
                const Text(
                  'Hoàn tất hồ sơ để trở thành đối tác',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),

                const SizedBox(height: 20),

                _buildAvatarSection(),

                const SizedBox(height: 0),

                _buildTextField(
                  controller: fullnameController,
                  label: 'Họ và tên',
                  hint: 'Nguyễn Văn A',
                ),

                const SizedBox(height: 8),

                _buildGenderSection(),

                const SizedBox(height: 16),

                // Province / District
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text('Tỉnh/Thành phố',
                          //   style: TextStyle(fontSize: 14, color: ColorConfig.textBlack)),
                          RequiredLabel(text: "Tỉnh/Thành phố"),
                          const SizedBox(height: 6),
                          _buildLocationField(
                            label: 'Chọn',
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
                          RequiredLabel(text: "Quận/Huyện"),
                           // Text('Quận/Huyện',
                           //    style: TextStyle(fontSize: 14, color: ColorConfig.textBlack)),
                          const SizedBox(height: 6),
                          _buildLocationField(
                            label: 'Chọn',
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

                const SizedBox(height: 6),

                _buildTextField(
                  controller: addressController,
                  label: 'Địa chỉ nơi ở',
                  hint: 'Số nhà, đường, khu phố...',
                ),

                const SizedBox(height: 10),

                // Year / Experience
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Text('Năm sinh', style: TextStyle(fontSize: 14, color: ColorConfig.textBlack)),
                              RequiredLabel(text: 'Năm sinh',),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Phải từ đủ 18 tuổi trở lên',
                                child: Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                          // const SizedBox(height: 6),

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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text('Kinh nghiệm',
                          //     style: TextStyle(fontSize: 14, color: ColorConfig.textBlack)),
                          RequiredLabel(text: "Kinh nghiệm",),
                          const SizedBox(height: 6),
                          _buildLocationField(
                            label: 'Chọn',
                            value: experience,
                            onTap: _showExperienceBottomSheet,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Services
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text('Dịch vụ cung cấp',
                    //   style: TextStyle(fontSize: 14, color: ColorConfig.textBlack)),
                    RequiredLabel(text: 'Dịch vụ cung cấp',),
                    const SizedBox(height: 6),
                    _buildLocationField(
                      label: 'Chọn dịch vụ',
                      value: selectedServiceIds.isEmpty
                          ? null
                          : '${selectedServiceIds.length} dịch vụ',
                      onTap: _showServicesBottomSheet,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Images section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // const Text(
                    //   'Hình ảnh',
                    //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    // ),
                    RequiredLabel(text: "Hình ảnh (3-5 ảnh)", fontWeight: FontWeight.bold,),
                    Text(
                      '${images.length}/5',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
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
                          if (shouldPop) context.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: const Text('Hủy', style: TextStyle(color: Color(0xFF666666))),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
        // Text(label, style: TextStyle(fontSize: 14, color: ColorConfig.textBlack)),
        RequiredLabel(text: label),
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