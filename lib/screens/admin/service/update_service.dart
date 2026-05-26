import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/service_service.dart';
import '../../../helper/logger_utils.dart';
import '../../../helper/snackbar_helper.dart';
import '../../../config/app_config.dart';

class UpdateService extends StatefulWidget {
  final Map<String, dynamic>? item;
  const UpdateService({super.key, required this.item});

  @override
  State<UpdateService> createState() => _UpdateServiceState();
}

class _UpdateServiceState extends State<UpdateService> {
  final Map<int, String?> _timePriceIds = {};
  final ServiceService _serviceService = ServiceService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, bool> _loadingPrice = {};

  bool _loadingInfo = false;
  final Map<String, dynamic>? dataItem = {};

  // Màu sắc spa theme
  final Color _spaPrimaryColor = const Color(0xFF5F8B55);
  final Color _spaSecondaryColor = const Color(0xFFD4B896);
  final Color _spaLightColor = const Color(0xFFF5E6D3);
  final Color _spaDarkColor = const Color(0xFF5D4037);
  final Color _spaAccentColor = const Color(0xFFC19A6B);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final item = widget.item!["item"];
    if (item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return;
    }

    // Khởi tạo thông tin cơ bản
    _nameController.text = item['name']?.toString() ?? '';
    _descriptionController.text = item['description']?.toString() ?? '';

    // Khởi tạo giá từ dữ liệu API
    final timePrices = item['timePrices'] as List? ?? [];
    for (final tp in timePrices) {
      final int? duration = tp['duration'] is int
          ? tp['duration']
          : int.tryParse(tp['duration'].toString());

      if (duration == null) continue;

      _timePriceIds[duration] = tp['_id']?.toString();

      _priceControllers[duration] = TextEditingController(
        text: tp['price']?.toString() ?? '0',
      );

      _loadingPrice[duration] = false;
    }

    for (final duration in AppConfig.time) {
      _priceControllers.putIfAbsent(
        duration,
            () => TextEditingController(text: ''),
      );
      _loadingPrice.putIfAbsent(duration, () => false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _updateInfo() async {
    if (_nameController.text.isEmpty) {
      SnackBarHelper.showError(context, 'Vui lòng nhập tên dịch vụ');
      return;
    }

    setState(() => _loadingInfo = true);
    try {
      await _serviceService.updateService(
        widget.item!['item']!['_id'],
        {
          'name': _nameController.text,
          'description': _descriptionController.text,
        },
      );
      SnackBarHelper.showSuccess(context, 'Đã cập nhật thông tin dịch vụ');
    } catch (e) {
      SnackBarHelper.showError(context, 'Cập nhật thất bại: ${e.toString()}');
    } finally {
      setState(() => _loadingInfo = false);
    }
  }

  Future<void> _updatePrice(int duration) async {
    final priceText = _priceControllers[duration]!.text;
    if (priceText.isEmpty) {
      SnackBarHelper.showError(context, 'Vui lòng nhập giá');
      return;
    }

    final price = int.tryParse(priceText);
    if (price == null || price <= 0) {
      SnackBarHelper.showError(context, 'Giá không hợp lệ');
      return;
    }

    setState(() => _loadingPrice[duration] = true);

    try {
      final timePriceId = _timePriceIds[duration];
      final data = {
        if (timePriceId != null) 'timePriceId': timePriceId,
        'duration': duration,
        'price': price,
      };

      final response = await _serviceService.addTimePriceService(
        widget.item!['item']!['_id'],
        data,
      );

      if (response != null && response['_id'] != null) {
        _timePriceIds[duration] = response['_id'].toString();
      }

      SnackBarHelper.showSuccess(context, 'Đã cập nhật giá $duration phút');
    } catch (e) {
      print('Update price error: $e');
      SnackBarHelper.showError(context, 'Cập nhật giá thất bại');
    } finally {
      setState(() => _loadingPrice[duration] = false);
    }
  }

  Widget _buildPriceItem(int duration) {
    final bool isLoading = _loadingPrice[duration] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _spaLightColor.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// TIME
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ColorConfig.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: ColorConfig.primary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  '$duration phút',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _spaDarkColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          /// INPUT + BUTTON
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: TextField(
                    controller: _priceControllers[duration],
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _spaDarkColor,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Nhập giá',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                      ),
                      prefixText: '₫ ',
                      prefixStyle: TextStyle(
                        color: ColorConfig.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => _updatePrice(duration),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: ColorConfig.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      'Cập nhật',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConfig.textWhite
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    String? title,
    String? subtitle,
    required Widget child,
    Color? titleColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: [
        //     _spaLightColor.withOpacity(0.1),
        //     Colors.white,
        //     _spaLightColor.withOpacity(0.05),
        //   ],
        // ),
        // borderRadius: BorderRadius.circular(20),
        // border: Border.all(color: _spaLightColor.withOpacity(0.3)),
        // boxShadow: [
        //   BoxShadow(
        //     color: _spaDarkColor.withOpacity(0.05),
        //     blurRadius: 15,
        //     offset: const Offset(0, 5),
        //   ),
        // ],
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if(titleColor != null && title != null && subtitle != null)... [
            Row(
              children: [
                if(titleColor != null) ...[
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: titleColor ?? _spaPrimaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                if(title != null) ...[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ColorConfig.textBlack,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],

              ],
            ),
            const SizedBox(height: 8),
            if(subtitle != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],

          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: ColorConfig.primaryBackground,
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
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Cập nhật dịch vụ",
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: const Center(
          child: Text('Không tìm thấy dữ liệu dịch vụ'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConfig.primaryBackground,
        elevation: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => context.pop(true),
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
            const Expanded(
              child: Text(
                "Cập nhật dịch vụ",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _spaLightColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== THÔNG TIN DỊCH VỤ =====
              _buildSection(
                // title: 'Thông tin dịch vụ',
                // subtitle: 'Cập nhật thông tin cơ bản của dịch vụ spa',
                // titleColor: const Color(0xFF4A6572),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên dịch vụ',
                        labelStyle: TextStyle(
                          color: _spaDarkColor.withOpacity(0.7),
                        ),
                        // prefixIcon: Icon(
                        //   Icons.spa,
                        //   color: _spaPrimaryColor,
                        // ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _spaLightColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _spaAccentColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: TextStyle(
                        color: _spaDarkColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Mô tả dịch vụ',
                        labelStyle: TextStyle(
                          color: _spaDarkColor.withOpacity(0.7),
                        ),
                        // prefixIcon: Icon(
                        //   Icons.description,
                        //   color: _spaPrimaryColor,
                        // ),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _spaLightColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _spaAccentColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: TextStyle(
                        color: _spaDarkColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            _spaPrimaryColor,
                            _spaAccentColor,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _spaPrimaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loadingInfo ? null : _updateInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConfig.primary,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _loadingInfo
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save,
                                  size: 20, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                'CẬP NHẬT THÔNG TIN',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== GIÁ THEO THỜI GIAN =====
              _buildSection(
                title: 'Giá theo thời gian',
                subtitle: 'Nhập và cập nhật giá cho từng khoảng thời gian dịch vụ',
                titleColor: ColorConfig.textBlack,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...AppConfig.time.map(
                          (duration) => _buildPriceItem(duration),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _spaLightColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _spaAccentColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _spaAccentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lưu ý: Nhấn "Cập nhật" bên cạnh từng mục để lưu giá riêng biệt',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _spaDarkColor.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}