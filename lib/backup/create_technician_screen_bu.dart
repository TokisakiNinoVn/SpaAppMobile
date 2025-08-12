// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:spa_app/config/color_config.dart';
// import 'package:spa_app/config/theme_config.dart';
// import 'package:spa_app/helper/snackbar_helper.dart';
//
// import 'package:spa_app/services/upload_service.dart';
// import 'package:spa_app/services/technician_service.dart';
// import 'package:spa_app/services/tinhthanh_service.dart';
// import 'package:spa_app/services/file_service.dart';
// import '../helper/format_helper.dart';
// import '../helper/full_screen_single_image.dart';
//
// class CreateTechnicianScreen extends StatefulWidget {
//   const CreateTechnicianScreen({super.key});
//
//   @override
//   State<CreateTechnicianScreen> createState() => _CreateTechnicianScreen();
// }
//
// class _CreateTechnicianScreen extends State<CreateTechnicianScreen> {
//   final fullnameController = TextEditingController();
//   final addressController = TextEditingController();
//   final experienceDescriptionController = TextEditingController();
//   final bioController = TextEditingController();
//   final technicianService = TechnicianService();
//   final tinhThanhService = TinhThanhService();
//
//   // State variables
//   bool isLoading = false;
//   List<dynamic> provinces = [];
//   List<dynamic> districts = [];
//   // List<dynamic> communes = [];
//   dynamic selectedProvince;
//   dynamic selectedDistrict;
//   dynamic selectedCommune;
//   String? experience;
//   List<Map<String, dynamic>> images = [];
//   Map<String, dynamic>? avatarImage;
//
//   // Bottom sheet controllers
//   final _provinceSearchController = TextEditingController();
//   final _districtSearchController = TextEditingController();
//   final _communeSearchController = TextEditingController();
//   final _experienceSearchController = TextEditingController();
//
//   // Filtered lists
//   List<dynamic> filteredProvinces = [];
//   List<dynamic> filteredDistricts = [];
//   List<dynamic> filteredCommunes = [];
//
//   // Dropdown loading states
//   bool isProvincesLoading = false;
//   bool isDistrictsLoading = false;
//   bool isCommunesLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _provinceSearchController.addListener(_filterProvinces);
//     _districtSearchController.addListener(_filterDistricts);
//     // _communeSearchController.addListener(_filterCommunes);
//     _loadProvinces();
//   }
//
//   @override
//   void dispose() {
//     _provinceSearchController.dispose();
//     _districtSearchController.dispose();
//     _communeSearchController.dispose();
//     _experienceSearchController.dispose();
//     fullnameController.dispose();
//     addressController.dispose();
//     experienceDescriptionController.dispose();
//     bioController.dispose();
//     super.dispose();
//   }
//
//   void _filterProvinces() {
//     final query = _provinceSearchController.text.toLowerCase();
//     setState(() {
//       filteredProvinces = provinces.where((province) {
//         return province['name'].toString().toLowerCase().contains(query);
//       }).toList();
//     });
//   }
//
//   void _filterDistricts() {
//     final query = _districtSearchController.text.toLowerCase();
//     setState(() {
//       filteredDistricts = districts.where((district) {
//         return district['name'].toString().toLowerCase().contains(query);
//       }).toList();
//     });
//   }
//
//   // void _filterCommunes() {
//   //   final query = _communeSearchController.text.toLowerCase();
//   //   setState(() {
//   //     filteredCommunes = communes.where((commune) {
//   //       return commune['name'].toString().toLowerCase().contains(query);
//   //     }).toList();
//   //   });
//   // }
//
//   Future<void> _loadProvinces() async {
//     setState(() => isProvincesLoading = true);
//     try {
//       final response = await tinhThanhService.getDetailsTinhThanhApiRoutesService();
//       if (response['code'] == 200 || response['status'] == 'success') {
//         setState(() {
//           provinces = response['data'];
//           filteredProvinces = provinces;
//         });
//       } else {
//         SnackbarHelper.showError(context, 'Không thể tải danh sách tỉnh thành');
//       }
//     } catch (e) {
//       SnackbarHelper.showError(context, 'Lỗi tải tỉnh thành: $e');
//     } finally {
//       setState(() => isProvincesLoading = false);
//     }
//   }
//
//   Future<void> _loadDistricts(String provinceId) async {
//     setState(() {
//       isDistrictsLoading = true;
//       districts = [];
//       filteredDistricts = [];
//       // communes = [];
//       filteredCommunes = [];
//       selectedDistrict = null;
//       selectedCommune = null;
//     });
//
//     try {
//       final response = await tinhThanhService.getDetailsHuyenApiRoutesService(provinceId);
//       if (response['code'] == 200 || response['status'] == 'success') {
//         setState(() {
//           districts = response['data'];
//           filteredDistricts = districts;
//         });
//       } else {
//         SnackbarHelper.showError(context, 'Không thể tải danh sách huyện');
//       }
//     } catch (e) {
//       SnackbarHelper.showError(context, 'Lỗi tải huyện: $e');
//     } finally {
//       setState(() => isDistrictsLoading = false);
//     }
//   }
//
//   // Future<void> _loadCommunes(String districtId) async {
//   //   setState(() {
//   //     isCommunesLoading = true;
//   //     communes = [];
//   //     filteredCommunes = [];
//   //     selectedCommune = null;
//   //   });
//   //
//   //   try {
//   //     final response = await tinhThanhService.getDetailsXaApiRoutesService(districtId);
//   //     if (response['code'] == 200 || response['status'] == 'success') {
//   //       setState(() {
//   //         communes = response['data'];
//   //         filteredCommunes = communes;
//   //       });
//   //     } else {
//   //       SnackbarHelper.showError(context, 'Không thể tải danh sách xã');
//   //     }
//   //   } catch (e) {
//   //     SnackbarHelper.showError(context, 'Lỗi tải xã: $e');
//   //   } finally {
//   //     setState(() => isCommunesLoading = false);
//   //   }
//   // }
//
//   Future<void> handleCreateTechnician() async {
//     final fullname = fullnameController.text.trim();
//     final address = addressController.text.trim();
//     final experienceDesc = experienceDescriptionController.text.trim();
//     final bio = bioController.text.trim();
//
//     // Validation
//     if (fullname.isEmpty) {
//       SnackbarHelper.showError(context, 'Vui lòng nhập họ tên');
//       return;
//     }
//     if (selectedProvince == null || selectedDistrict == null || selectedCommune == null) {
//     // if (selectedProvince == null || selectedDistrict == null) {
//       SnackbarHelper.showError(context, 'Vui lòng chọn đầy đủ địa chỉ');
//       return;
//     }
//     if (address.isEmpty) {
//       SnackbarHelper.showError(context, 'Vui lòng nhập địa chỉ cụ thể');
//       return;
//     }
//     if (experience == null) {
//       SnackbarHelper.showError(context, 'Vui lòng chọn kinh nghiệm');
//       return;
//     }
//     if (images.length < 3) {
//       SnackbarHelper.showError(context, 'Vui lòng chọn tối thiểu 3 ảnh');
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       final data = {
//         'avatar': avatarImage,
//         'fullName': fullname,
//         'province': selectedProvince['name'],
//         'district': selectedDistrict['name'],
//         'commune': selectedCommune['name'] ?? '--',
//         'address': address,
//         'experience': experience,
//         'experienceDescription': experienceDesc,
//         'images': images,
//         'bio': bio,
//       };
//
//       final response = await technicianService.createTechnicianService(data);
//       if (response['success'] == true) {
//         SnackbarHelper.showSuccess(context, 'Hồ sơ của bạn đã tạo thành công, chờ duyệt');
//         context.go('/login');
//       } else {
//         SnackbarHelper.showError(context, response['message'] ?? 'Có lỗi xảy ra khi tạo hồ sơ');
//         print('Lỗi khi tạo hồ sơ: ${response['message']}');
//       }
//     } catch (e) {
//       SnackbarHelper.showError(context, 'Lỗi hệ thống: $e');
//       print('Lỗi hệ thống: $e');
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   Future<void> uploadImage(String filePath, {bool isAvatar = false}) async {
//     try {
//       final uploadService = UploadService();
//       final response = await uploadService.uploadSingleFileService(filePath);
//       final imageData = response['data'];
//
//       if (imageData != null) {
//         setState(() {
//           if (isAvatar) {
//             avatarImage = imageData;
//           } else {
//             images.add(imageData);
//           }
//         });
//       } else {
//         SnackbarHelper.showError(context, 'Không thể tải lên hình ảnh');
//       }
//     } catch (e) {
//       SnackbarHelper.showError(context, 'Lỗi tải lên hình ảnh: $e');
//     }
//   }
//
//   Future<void> _pickImage({bool isAvatar = false}) async {
//     if (!isAvatar && images.length >= 5) {
//       SnackbarHelper.showError(context, 'Bạn chỉ được chọn tối đa 5 ảnh');
//       return;
//     }
//
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       if (isAvatar) {
//         await _cropImage(File(pickedFile.path), isAvatar: true);
//       } else {
//         await uploadImage(pickedFile.path);
//       }
//     }
//   }
//
//   Future<void> _cropImage(File imageFile, {bool isAvatar = false}) async {
//     final croppedFile = await ImageCropper().cropImage(
//       sourcePath: imageFile.path,
//       aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
//       uiSettings: [
//         AndroidUiSettings(
//           toolbarTitle: 'Cắt ảnh',
//           toolbarColor: const Color(0xFF8B5E3C),
//           toolbarWidgetColor: Colors.white,
//           initAspectRatio: CropAspectRatioPreset.square,
//           lockAspectRatio: true,
//         ),
//         IOSUiSettings(
//           title: 'Cắt ảnh',
//           aspectRatioLockEnabled: true,
//           resetAspectRatioEnabled: false,
//           aspectRatioPickerButtonHidden: true,
//         ),
//       ],
//     );
//
//     if (croppedFile != null) {
//       await uploadImage(croppedFile.path, isAvatar: isAvatar);
//     }
//   }
//
//   Future<void> deleteImage(String idImage) async {
//     try {
//       final fileService = FileService();
//       final response = await fileService.deleteFileService(idImage);
//
//       if (response['status'] == 'success') {
//         SnackbarHelper.showSuccess(context, 'Hình ảnh đã được xóa');
//         setState(() => images.removeWhere((img) => img['_id'] == idImage));
//       } else {
//         SnackbarHelper.showError(context, 'Không thể xóa hình ảnh');
//       }
//     } catch (e) {
//       SnackbarHelper.showError(context, 'Lỗi xóa hình ảnh: $e');
//     }
//   }
//
//   void _showFullScreenImage(String imageUrl) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog.fullscreen(
//         child: Stack(
//           children: [
//             Center(
//               child: Image.network(
//                 imageUrl,
//                 fit: BoxFit.contain,
//               ),
//             ),
//             Positioned(
//               top: 40,
//               right: 20,
//               child: IconButton(
//                 icon: const Icon(Icons.close, size: 30, color: Colors.white),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLocationField({
//     required String label,
//     required String? value,
//     required VoidCallback onTap,
//     bool isLoading = false,
//   }) {
//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.9),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.grey[300]!),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 value ?? label,
//                 style: ThemeConfig.appTextStyle(
//                   color: value != null ? ColorConfig.textPrimary : Colors.grey,
//                 ),
//               ),
//             ),
//             if (isLoading)
//               const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               )
//             else
//               const Icon(Icons.arrow_drop_down, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showProvinceBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => _buildLocationBottomSheet(
//         title: 'Chọn tỉnh/thành',
//         controller: _provinceSearchController,
//         items: filteredProvinces,
//         onSelected: (province) {
//           setState(() => selectedProvince = province);
//           _loadDistricts(province['idProvince']);
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }
//
//   void _showDistrictBottomSheet() {
//     if (selectedProvince == null) {
//       SnackbarHelper.showError(context, 'Vui lòng chọn tỉnh trước');
//       return;
//     }
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => _buildLocationBottomSheet(
//         title: 'Chọn quận/huyện',
//         controller: _districtSearchController,
//         items: filteredDistricts,
//         onSelected: (district) {
//           setState(() => selectedDistrict = district);
//           // _loadCommunes(district['idDistrict']);
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }
//
//   void _showCommuneBottomSheet() {
//     if (selectedDistrict == null) {
//       SnackbarHelper.showError(context, 'Vui lòng chọn huyện trước');
//       return;
//     }
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => _buildLocationBottomSheet(
//         title: 'Chọn phường/xã',
//         controller: _communeSearchController,
//         items: filteredCommunes,
//         onSelected: (commune) {
//           setState(() => selectedCommune = commune);
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }
//
//   void _showExperienceBottomSheet() {
//     final experiences = ['Có kinh nghiệm', 'Không có kinh nghiệm'];
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Chọn kinh nghiệm',
//               style: ThemeConfig.appTextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...experiences.map((exp) => ListTile(
//               title: Text(exp),
//               onTap: () {
//                 setState(() => experience = exp);
//                 Navigator.pop(context);
//               },
//             )),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLocationBottomSheet({
//     required String title,
//     required TextEditingController controller,
//     required List<dynamic> items,
//     required Function(dynamic) onSelected,
//   }) {
//     return Container(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//         left: 16,
//         right: 16,
//         top: 40,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             title,
//             style: ThemeConfig.appTextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: controller,
//             decoration: InputDecoration(
//               labelText: 'Tìm kiếm',
//               prefixIcon: const Icon(Icons.search),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: ListView.builder(
//               itemCount: items.length,
//               itemBuilder: (context, index) {
//                 final item = items[index];
//                 return ListTile(
//                   title: Text(item['name']),
//                   onTap: () => onSelected(item),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImageGrid() {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//         childAspectRatio: 1,
//       ),
//       itemCount: images.length + (images.length < 5 ? 1 : 0),
//       itemBuilder: (context, index) {
//         if (index == images.length) {
//           return GestureDetector(
//             onTap: () => _pickImage(),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
//             ),
//           );
//         }
//
//         final image = images[index];
//         return Stack(
//           children: [
//             GestureDetector(
//               onTap: () => FullScreenSingleImageViewer(
//                   imageUrl: FormatHelper.formatImageUrl(image['url'])),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.network(
//                   FormatHelper.formatImageUrl(image['url']),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 4,
//               right: 4,
//               child: GestureDetector(
//                 onTap: () => deleteImage(image['_id']),
//                 child: Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: const BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(Icons.close, size: 16, color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildAvatarSection() {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: () {
//             if (avatarImage != null) {
//               _showFullScreenImage(FormatHelper.formatImageUrl(avatarImage!['url']));
//             }
//           },
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               Container(
//                 width: 120,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(color: const Color(0xFFD4A373), width: 2),
//                 ),
//                 child: ClipOval(
//                   child: avatarImage != null
//                       ? Image.network(
//                     FormatHelper.formatImageUrl(avatarImage!['url']),
//                     fit: BoxFit.cover,
//                     width: 110,
//                     height: 110,
//                   )
//                       : const Icon(Icons.person, size: 60, color: Colors.grey),
//                 ),
//               ),
//               if (avatarImage != null)
//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         avatarImage = null;
//                       });
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: const BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(Icons.close, size: 20, color: Colors.white),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 10),
//         ElevatedButton.icon(
//           onPressed: () => _pickImage(isAvatar: true),
//           icon: const Icon(Icons.camera_alt),
//           label: const Text('Chọn ảnh đại diện'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFFD4A373),
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//           ),
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFF8F4E9), Color(0xFFE9D8C8)],
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'Serene Spa',
//                   style: GoogleFonts.playfairDisplay(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     color: ColorConfig.textPrimary,
//                   ),
//                 ),
//                 Text(
//                   'Tạo hồ sơ kĩ thuật viên',
//                   style: ThemeConfig.appTextStyle(
//                       fontSize: 18, color: ColorConfig.textPrimary),
//                 ),
//                 const SizedBox(height: 40),
//                 _buildAvatarSection(),
//                 _buildTextField(
//                   controller: fullnameController,
//                   label: 'Họ và tên',
//                   icon: Icons.person,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildLocationField(
//                   label: 'Chọn tỉnh/thành',
//                   value: selectedProvince?['name'],
//                   onTap: _showProvinceBottomSheet,
//                   isLoading: isProvincesLoading,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildLocationField(
//                   label: 'Chọn quận/huyện',
//                   value: selectedDistrict?['name'],
//                   onTap: _showDistrictBottomSheet,
//                   isLoading: isDistrictsLoading,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildLocationField(
//                   label: 'Chọn phường/xã',
//                   value: selectedCommune?['name'],
//                   onTap: _showCommuneBottomSheet,
//                   isLoading: isCommunesLoading,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   controller: addressController,
//                   label: 'Địa chỉ cụ thể',
//                   icon: Icons.location_on,
//                   maxLines: 3,
//                   maxLength: 150,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildLocationField(
//                   label: 'Chọn kinh nghiệm',
//                   value: experience,
//                   onTap: _showExperienceBottomSheet,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   controller: experienceDescriptionController,
//                   label: 'Mô tả kinh nghiệm (tối đa 200 ký tự)',
//                   icon: Icons.description,
//                   maxLines: 3,
//                   maxLength: 200,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   controller: bioController,
//                   label: 'Giới thiệu bản thân (tối đa 100 ký tự)',
//                   icon: Icons.info,
//                   maxLength: 100,
//                   maxLines: 2,
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Text('Hình ảnh (tối thiểu 3, tối đa 5 ảnh)',
//                         style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary)),
//                     const SizedBox(width: 8),
//                     if (images.isNotEmpty)
//                       Text('(${images.length}/5)',
//                           style: ThemeConfig.appTextStyle(color: ColorConfig.textSecondary)),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 _buildImageGrid(),
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: isLoading ? null : handleCreateTechnician,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       backgroundColor: ColorConfig.secondary,
//                       foregroundColor: ColorConfig.textWhite,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16)),
//                       elevation: 5,
//                       shadowColor: Colors.black.withOpacity(0.2),
//                     ),
//                     child: isLoading
//                         ? const CircularProgressIndicator(
//                         strokeWidth: 2, color: Colors.white)
//                         : Text('Tạo hồ sơ',
//                         style: ThemeConfig.appTextStyle(
//                             color: ColorConfig.textWhite,
//                             fontWeight: FontWeight.bold)),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       context.go('/login');
//                     },
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 16, horizontal: 20),
//                       backgroundColor: ColorConfig.grey,
//                       foregroundColor: ColorConfig.textWhite,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 5,
//                       shadowColor: Colors.black.withOpacity(0.2),
//                     ),
//                     icon: const Icon(Icons.arrow_back, size: 20),
//                     label: Text(
//                       'Hủy',
//                       style: ThemeConfig.appTextStyle(
//                         color: ColorConfig.textWhite,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     int maxLines = 1,
//     int? maxLength,
//   }) {
//     return TextField(
//       controller: controller,
//       maxLines: maxLines,
//       maxLength: maxLength,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: const Color(0xFF8B5E3C)),
//         labelStyle: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary),
//         filled: true,
//         fillColor: Colors.white.withOpacity(0.9),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: const BorderSide(color: Color(0xFFD4A373), width: 2),
//         ),
//         contentPadding:
//         const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//       ),
//       style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary),
//     );
//   }
// }