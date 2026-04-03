import 'package:flutter/material.dart';
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
  final Color _spaPrimaryColor = const Color(0xFF8B7355);
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
      SnackbarHelper.showError(context, 'Vui lòng nhập tên dịch vụ');
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
      SnackbarHelper.showSuccess(context, 'Đã cập nhật thông tin dịch vụ');
    } catch (e) {
      SnackbarHelper.showError(context, 'Cập nhật thất bại: ${e.toString()}');
    } finally {
      setState(() => _loadingInfo = false);
    }
  }

  Future<void> _updatePrice(int duration) async {
    final priceText = _priceControllers[duration]!.text;
    if (priceText.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng nhập giá');
      return;
    }

    final price = int.tryParse(priceText);
    if (price == null || price <= 0) {
      SnackbarHelper.showError(context, 'Giá không hợp lệ');
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

      SnackbarHelper.showSuccess(context, 'Đã cập nhật giá $duration phút');
    } catch (e) {
      print('Update price error: $e');
      SnackbarHelper.showError(context, 'Cập nhật giá thất bại');
    } finally {
      setState(() => _loadingPrice[duration] = false);
    }
  }

  Widget _buildPriceItem(int duration) {
    final bool isLoading = _loadingPrice[duration] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: _spaLightColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _spaLightColor.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// ===== DÒNG 1: PHÚT + GIÁ =====
          Row(
            children: [
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _spaPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _spaPrimaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  '$duration phút',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _spaDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _priceControllers[duration],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixText: 'đ ',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _spaAccentColor,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _spaDarkColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ===== DÒNG 2: NÚT CẬP NHẬT =====
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _updatePrice(duration),
              style: ElevatedButton.styleFrom(
                backgroundColor: _spaPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
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
                  : const Text(
                'Cập nhật',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
    Color? titleColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _spaLightColor.withOpacity(0.1),
            Colors.white,
            _spaLightColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _spaLightColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _spaDarkColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: titleColor ?? _spaPrimaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? _spaDarkColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 24),
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
          title: const Text('Cập nhật dịch vụ'),
        ),
        body: const Center(
          child: Text('Không tìm thấy dữ liệu dịch vụ'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật dịch vụ'),
        backgroundColor: _spaPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                title: 'Thông tin dịch vụ',
                subtitle: 'Cập nhật thông tin cơ bản của dịch vụ spa',
                titleColor: const Color(0xFF4A6572),
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
                        prefixIcon: Icon(
                          Icons.spa,
                          color: _spaPrimaryColor,
                        ),
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
                        prefixIcon: Icon(
                          Icons.description,
                          color: _spaPrimaryColor,
                        ),
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
                            backgroundColor: Colors.transparent,
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
                titleColor: const Color(0xFF5D4037),
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