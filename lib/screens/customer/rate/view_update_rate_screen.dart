import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/rate_service.dart'; // Thêm service rate

class ViewOrUpdateRateScreen extends StatefulWidget {
  final Map<String, dynamic>? data;

  const ViewOrUpdateRateScreen({
    super.key,
    this.data,
  });

  @override
  State<ViewOrUpdateRateScreen> createState() => _ViewOrUpdateRateScreenState();
}

class _ViewOrUpdateRateScreenState extends State<ViewOrUpdateRateScreen> {
  final RateService _rateService = RateService();
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  int _rating = 0;
  String? _rateId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Khởi tạo dữ liệu từ widget.data
    if (widget.data != null) {
      _rating = widget.data!['score'] ?? 0;
      _commentController.text = widget.data!['comment'] ?? '';
      _rateId = widget.data!['id'];
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateRating() async {
    if (_rating == 0) {
      SnackBarHelper.showError(context, 'Vui lòng chọn số sao đánh giá');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_rateId == null) {
      SnackBarHelper.showError(context, 'Không tìm thấy ID đánh giá để cập nhật');
      return;
    }

    final Map<String, dynamic> updateData = {
      'score': _rating,
      'comment': _commentController.text.trim(),
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _rateService.updateRate(_rateId!, updateData);
      if (response['success'] == true || response['status'] == 'success') {
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Cập nhật đánh giá thành công');
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, true); // Trả về true để refresh màn hình trước
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showError(context, 'Cập nhật thất bại, vui lòng thử lại');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarHelper.showError(context, 'Lỗi: ${e.toString()}');
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = starValue;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              starValue <= _rating ? Icons.star : Icons.star_border,
              color: starValue <= _rating ? Colors.amber : Colors.grey.shade400,
              size: 48,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra dữ liệu đầu vào
    final hasData = widget.data != null && _rateId != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
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
              "Chi tiết & Cập nhật đánh giá",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: hasData
              ? Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chất lượng dịch vụ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _buildStarRating(),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _rating == 0
                        ? 'Chọn số sao của bạn'
                        : 'Bạn đã chọn $_rating sao',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Bình luận
                const Text(
                  'Chia sẻ trải nghiệm của bạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Hãy cho chúng tôi biết cảm nhận của bạn...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) {
                      if (value != null && value.length > 500) {
                        return 'Nội dung không được vượt quá 500 ký tự';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Nút cập nhật
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ColorConfig.primary, ColorConfig.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'CẬP NHẬT ĐÁNH GIÁ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Cảm ơn bạn đã đóng góp ý kiến để chúng tôi phục vụ tốt hơn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Không có dữ liệu đánh giá',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng quay lại và chọn đánh giá hợp lệ',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}