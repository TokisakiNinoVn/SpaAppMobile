import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/banner_service.dart';
import '../../../../helper/snackbar_helper.dart';

class BannerManagement extends StatefulWidget {
  const BannerManagement({super.key});

  @override
  _BannerManagementState createState() => _BannerManagementState();
}

class _BannerManagementState extends State<BannerManagement>
    with SingleTickerProviderStateMixin {
  final BannerService bannerService = BannerService();

  List<Map<String, dynamic>> banners = [];
  bool isLoading = true;
  bool displayStatus = true;
  int numberOfBanners = 0;
  int totalDocs = 0;

  final TextEditingController numberOfBannersController =
  TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Design tokens
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFEFF6FF);
  static const _surface = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _success = Color(0xFF16A34A);
  static const _successLight = Color(0xFFF0FDF4);
  static const _danger = Color(0xFFDC2626);
  static const _dangerLight = Color(0xFFFEF2F2);
  static const _warning = Color(0xFFD97706);
  static const _warningLight = Color(0xFFFFFBEB);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    loadBanners();
  }

  Future<void> loadBanners() async {
    setState(() => isLoading = true);
    try {
      final response = await bannerService.listStatusAdminBanner();
      if (response['success'] == true || response['message'] != null) {
        setState(() {
          displayStatus = response['display'] ?? true;
          numberOfBanners = response['numberOfBanners'] ?? 0;
          totalDocs = response['totalDocs'] ?? 0;
          banners =
          List<Map<String, dynamic>>.from(response['data'] ?? []);
          isLoading = false;
        });
        _animController
          ..reset()
          ..forward();
      } else {
        throw Exception(
            response['message'] ?? 'Không thể tải danh sách banner');
      }
    } catch (e) {
      setState(() => isLoading = false);
      SnackBarHelper.showError(context, 'Lỗi khi tải danh sách banner: $e');
    }
  }

  Future<void> deleteBanner(String id, String title) async {
    final confirm = await _showDeleteDialog(title);
    if (confirm != true) return;

    try {
      final response = await bannerService.deleteBanner(id);
      if (response['success'] == true || response['message'] != null) {
        SnackBarHelper.showSuccess(context, 'Xóa banner thành công');
        loadBanners();
      } else {
        throw Exception(response['message'] ?? 'Không thể xóa banner');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi khi xóa banner: $e');
    }
  }

  Future<bool?> _showDeleteDialog(String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _dangerLight, shape: BoxShape.circle),
                child:
                const Icon(Icons.delete_outline_rounded, color: _danger, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Xác nhận xóa',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Bạn có chắc chắn muốn xóa banner\n"$title"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Hủy',
                          style: TextStyle(color: _textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Xóa',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateDisplayStatus(bool newValue) async {
    try {
      final response = await bannerService.configDisplayBanner({
        'displayBanner': newValue,
      });
      if (response['success'] == true || response['message'] != null) {
        setState(() => displayStatus = newValue);
        SnackBarHelper.showSuccess(
            context,
            newValue
                ? 'Đã bật hiển thị banner'
                : 'Đã tắt hiển thị banner');
        loadBanners();
      } else {
        throw Exception(response['message'] ??
            'Không thể cập nhật trạng thái hiển thị');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi khi cập nhật trạng thái: $e');
    }
  }

  Future<void> updateNumberOfBanners() async {
    numberOfBannersController.text = numberOfBanners.toString();

    final newValue = await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _primaryLight,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.tune_rounded,
                        color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Cấu hình số lượng',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Số lượng banner hiển thị',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: numberOfBannersController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                    fontSize: 15, color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Nhập số lượng...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: _primary, width: 1.5)),
                  filled: true,
                  fillColor: _surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Hủy',
                          style: TextStyle(color: _textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = int.tryParse(
                            numberOfBannersController.text);
                        if (value != null && value > 0) {
                          Navigator.pop(context, value);
                        } else {
                          SnackBarHelper.showError(
                              context, 'Vui lòng nhập số hợp lệ');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Lưu',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newValue == null) return;

    try {
      final response = await bannerService
          .configNumberBanner({'numberOfBanners': newValue});
      if (response['success'] == true || response['message'] != null) {
        setState(() => numberOfBanners = newValue);
        SnackBarHelper.showSuccess(
            context, 'Đã cập nhật số lượng banner hiển thị');
        loadBanners();
      } else {
        throw Exception(response['message'] ??
            'Không thể cập nhật số lượng banner');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi khi cập nhật số lượng: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: _primary))
          : FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildConfigCard(),
            Expanded(child: _buildBannerList()),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: _textPrimary,
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Quản lý Banner',
        style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textPrimary),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          color: _textSecondary,
          onPressed: loadBanners,
          tooltip: 'Làm mới',
        ),
      ],
    );
  }

  Widget _buildConfigCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Global display toggle
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                    displayStatus ? _primaryLight : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    displayStatus
                        ? Icons.view_carousel_rounded
                        : Icons.hide_image_rounded,
                    size: 20,
                    color: displayStatus ? _primary : _textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hiển thị Banner',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        displayStatus
                            ? 'Banner đang hiển thị trên ứng dụng'
                            : 'Banner đang bị ẩn toàn bộ',
                        style: const TextStyle(
                            fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Switch.adaptive(
                    value: displayStatus,
                    onChanged: updateDisplayStatus,
                    activeColor: ColorConfig.primary,
                    activeTrackColor: ColorConfig.primary.withOpacity(.3),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: _border),

          // Stats + config row
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.visibility_rounded,
                  label: 'Max hiển thị',
                  value: '$numberOfBanners',
                  color: _primary,
                  bg: _primaryLight,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.photo_library_rounded,
                  label: 'Tổng banner',
                  value: '$totalDocs',
                  color: _warning,
                  bg: _warningLight,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: updateNumberOfBanners,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 14, color: _primary),
                        SizedBox(width: 6),
                        Text('Cấu hình',
                            style: TextStyle(
                                fontSize: 13,
                                color: _primary,
                                fontWeight: FontWeight.w600)),
                      ],
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

  Widget _buildBannerList() {
    if (banners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: _primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.image_search_rounded,
                  size: 48, color: _primary),
            ),
            const SizedBox(height: 20),
            const Text('Chưa có banner nào',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 6),
            const Text('Nhấn nút + để thêm banner mới',
                style: TextStyle(fontSize: 13, color: _textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: banners.length,
      itemBuilder: (context, index) {
        final banner = banners[index];
        return _BannerCard(
          banner: banner,
          onEdit: () => context.push(AdminRouterConfig.editBanner, extra: banner),
          onDelete: () =>
              deleteBanner(banner['_id'] ?? '', banner['title'] ?? ''),
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.push(AdminRouterConfig.createBanner),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Thêm banner',
          style: TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    numberOfBannersController.dispose();
    super.dispose();
  }
}

// ────────────────────────────────────────────────────────────
// Banner Card Widget
// ────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFEFF6FF);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _success = Color(0xFF16A34A);
  static const _successLight = Color(0xFFF0FDF4);
  static const _danger = Color(0xFFDC2626);
  static const _dangerLight = Color(0xFFFEF2F2);

  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = banner['title'] ?? 'Không có tiêu đề';
    final content = banner['content'] ?? '';
    final imageUrl = banner['urlImage'] ?? '';
    final display = banner['display'] ?? true;
    final createdAt = banner['createdAt'] != null
        ? DateTime.parse(banner['createdAt']).toLocal()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(15)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  FormatHelper.formatNetworkImageUrl(imageUrl),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
                    : _imagePlaceholder(),
              ),
              // Display badge on image
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: display ? _successLight : _dangerLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: display
                            ? _success.withOpacity(0.3)
                            : _danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: display ? _success : _danger,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        display ? 'Hiển thị' : 'Ẩn',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: display ? _success : _danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(content,
                      style: const TextStyle(
                          fontSize: 13, color: _textSecondary, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        FormatHelper.formatDateTimeTypeDateTime(createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 15),
                        label: const Text('Chỉnh sửa'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: _primary),
                          foregroundColor: _primary,
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 15),
                        label: const Text('Xóa'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: _danger),
                          foregroundColor: _danger,
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_rounded,
              size: 36, color: Color(0xFFCBD5E1)),
          SizedBox(height: 6),
          Text('Không có ảnh',
              style:
              TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Stat chip
// ────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B))),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}