import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/information_service.dart';
import 'package:spa_app/services/user_discount_service.dart';

import 'widgets/featured_services_widget.dart';

class ListFeatureService extends StatefulWidget {
  const ListFeatureService({
    super.key,
  });

  @override
  State<ListFeatureService> createState() => _ListFeatureServiceState();
}

class _ListFeatureServiceState extends State<ListFeatureService> {
  final InformationService _informationService = InformationService();
  List<dynamic> _featureServices = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // RefreshIndicator key để điều khiển programmatically
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _fetchFeatureServices();
  }

  /// Hàm fetch dữ liệu chính, hỗ trợ cả loading lần đầu và refresh
  Future<void> _fetchFeatureServices({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _informationService.listFeatureService();
      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          _featureServices = response['data'];
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể tải dữ liệu';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// Hàm refresh được gọi khi kéo xuống
  Future<void> _onRefresh() async {
    await _fetchFeatureServices(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Chỉnh sửa hiển thị",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5E9B8C),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchFeatureServices(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E9B8C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : _featureServices.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có dữ liệu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            // Thêm nút refresh khi không có dữ liệu
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E9B8C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        color: const Color(0xFF5E9B8C),
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 40,
        // Hiệu ứng kéo thả đẹp mắt
        notificationPredicate: (ScrollNotification notification) {
          // Chỉ kích hoạt khi scroll ở đầu danh sách
          return notification.depth == 0;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(0),
          itemCount: _featureServices.length,
          separatorBuilder: (context, index) =>
          const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _featureServices[index];
            final fileId = item['fileId'] ?? {};
            final imageUrl = fileId['url'] ?? '';

            return FeaturedServicesAdminWidget(
              title: item['title'] ?? 'Không có tiêu đề',
              description:
              item['description'] ?? 'Không có mô tả',
              tag: item['tag'] ?? '',
              imageUrl: imageUrl,
              extra: Map<String, dynamic>.from(item),
            );
          },
        ),
      ),
    );
  }
}