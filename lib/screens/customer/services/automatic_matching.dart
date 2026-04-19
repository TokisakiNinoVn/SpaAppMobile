import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/notification_service.dart';
import '../../../helper/format_helper.dart';
import '../../../routes/config/customer_router_config.dart';

class BookScreen extends StatefulWidget {
  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final NotificationService _notificationService = NotificationService();

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFavorite = false;
  Map<String, dynamic>? _selectedService;
  int? _selectedTimeIndex;
  bool _showBookingBottomSheet = false;

  // State management
  Map<String, dynamic>? _technicianDetails;
  List<dynamic> _notificationList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final Color _primaryColor = const Color(0xFF8B7355);
  final Color _secondaryColor = const Color(0xFFD4B996);
  final Color _accentColor = const Color(0xFFC19A6B);
  final Color _backgroundColor = const Color(0xFFF8F5F0);
  final Color _textColor = const Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    _loadListNotification();
  }

  Future<void> _loadListNotification() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _notificationService.listNotificationService();

      if (response['success'] == true) {
        setState(() {
          _notificationList = response['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải thông tin kỹ thuật viên');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading technician details: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId, int index) async {
    try {
      final response = await _notificationService.deleteNotificationService(notificationId);

      if (response['success'] == true) {
        setState(() {
          _notificationList.removeAt(index);
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể xóa thông báo');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa thông báo thất bại')),
      );
    }
  }

  void _showDeleteConfirmDialog(String notificationId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thông báo'),
        content: const Text('Bạn có chắc muốn xóa thông báo này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNotification(notificationId, index);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: _backgroundColor,
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
                    color: _backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: _textColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Thông báo",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(
          child: Text(
            _errorMessage,
            style: TextStyle(color: Colors.red),
          ),
        )
            : _notificationList.isEmpty
            ? Center(
          child: Text(
            "Chưa có thông báo nào",
            style: TextStyle(color: _textColor),
          ),
        )
            : ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _notificationList.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: _secondaryColor.withOpacity(0.4),
          ),
          itemBuilder: (context, index) {
            final noti = _notificationList[index];
            final bool isRead = noti['isRead'] == true;

            return InkWell(
              onTap: () {
                // context.push(
                //   CustomerRoutes.notificationDetail,
                //   extra: noti,
                // );
              },
              child: Container(
                color: isRead
                    ? Colors.white
                    : _secondaryColor.withOpacity(0.25),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 10),
                    Icon(
                      FontAwesomeIcons.bullhorn,
                      size: 24,
                      color: isRead ? _accentColor : _primaryColor,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            noti['title'] ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w700,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            noti['content'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            FormatHelper.formatDateTime(noti['createdAt']),
                            style: TextStyle(
                              fontSize: 11,
                              color: _textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: _textColor.withOpacity(0.6),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteConfirmDialog(noti['_id'], index);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Xóa thông báo'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
  }
}