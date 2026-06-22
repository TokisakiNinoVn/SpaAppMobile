import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/user_service.dart';
import '../../../../helper/snackbar_helper.dart';
import '../../../services/notification_service.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  _NotificationManagementScreenState createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen> {
  final UserService userService = UserService();
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> filteredNotifications = [];
  bool isLoading = true;

  // FIX: Bỏ ScrollController vì gây conflict với RefreshIndicator.
  // RefreshIndicator tự xử lý pull-to-refresh mà không cần custom listener.

  // Filter variables
  String? selectedType;
  String? selectedMode;
  String? selectedStatus;
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  final List<String> modeOptions = ['once', 'daily_time', 'interval'];

  // FIX: typeOfRecipient dùng kiểu String (value) thống nhất với selectedType (String?)
  final List<Map<String, String>> typeOfRecipient = [
    {"name": "Khách hàng", "value": "customer"},
    {"name": "Kỹ thuật viên", "value": "ktv"},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // FIX: Bỏ _onScroll và _scrollController listener — RefreshIndicator đã đủ.

  Future<void> _onRefresh() async {
    await _loadNotifications();
  }

  /// Parse ISO-8601 string (có thể là UTC hoặc local) rồi convert sang local time của thiết bị.
  /// DateTime.parse() tự nhận suffix 'Z' là UTC; nếu không có suffix thì coi là local.
  /// Gọi .toLocal() để đảm bảo luôn hiển thị theo múi giờ thiết bị (VD: UTC+7 → +7h).
  String _formatDateTime(String? dateTimeString, {bool showRelative = true}) {
    if (dateTimeString == null) return 'Chưa xác định';

    try {
      // .toLocal() converts UTC → device timezone (e.g. Asia/Ho_Chi_Minh UTC+7)
      final DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
      final DateTime now = DateTime.now();

      if (showRelative) {
        final difference = now.difference(dateTime);

        if (difference.abs().inMinutes < 1) {
          return 'Vừa xong';
        } else if (difference.abs().inHours < 1) {
          return '${difference.abs().inMinutes} phút trước';
        } else if (difference.abs().inDays < 1) {
          return '${difference.abs().inHours} giờ trước';
        } else if (difference.abs().inDays < 7) {
          return '${difference.abs().inDays} ngày trước';
        }
      }

      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  String _getModeDisplayName(String? mode, Map<String, dynamic>? notification) {
    if (mode == null) return 'Không xác định';

    switch (mode) {
      case 'once':
        return 'Gửi một lần';
      case 'daily_time':
        if (notification != null &&
            notification['schedule'] != null &&
            notification['schedule']['daysOfWeek'] != null &&
            (notification['schedule']['daysOfWeek'] as List).isNotEmpty) {
          return 'Lặp theo tuần';
        }
        return 'Lặp theo ngày';
      case 'interval':
        return 'Lặp theo khoảng thời gian';
      default:
        return mode;
    }
  }

  String _getModeText(String? mode) {
    switch (mode) {
      case 'once':
        return 'Một lần';
      case 'daily_time':
        return 'Lặp theo lịch';
      case 'interval':
        return 'Lặp khoảng thời gian';
      default:
        return mode ?? 'Không xác định';
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _notificationService.listNotificationService();
      if (response['success'] == true) {
        setState(() {
          notifications = List<Map<String, dynamic>>.from(
              response['data']['notifications'] ?? []);
          _applyFilters();
          isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải thông báo');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        SnackBarHelper.showError(context, 'Lỗi khi tải thông báo: $e');
      }
    }
  }

  void _applyFilters() {
    filteredNotifications = notifications.where((notification) {
      // Filter by type
      if (selectedType != null && selectedType != 'all') {
        if (notification['typeNotification'] != selectedType) {
          return false;
        }
      }

      // Filter by schedule mode
      if (selectedMode != null) {
        String mode = notification['schedule']?['mode'] ?? '';
        if (mode != selectedMode) {
          return false;
        }
      }

      // Filter by status
      if (selectedStatus != null) {
        bool isSent = notification['isSent'] ?? false;
        switch (selectedStatus) {
          case 'sent':
            if (!isSent) return false;
            break;
          case 'pending':
            if (isSent) return false;
            break;
          case 'scheduled':
            if (isSent) return false;
            break;
        }
      }

      // Search by title or content
      if (searchQuery.isNotEmpty) {
        String title = notification['title']?.toLowerCase() ?? '';
        String content = notification['content']?.toLowerCase() ?? '';
        if (!title.contains(searchQuery.toLowerCase()) &&
            !content.contains(searchQuery.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();

    setState(() {});
  }

  Future<void> _deleteNotification(String id, String title) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thông báo "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response =
        await _notificationService.deleteNotificationService(id);
        if (response['success'] == true) {
          if (mounted) {
            SnackBarHelper.showSuccess(context, 'Xóa thông báo thành công');
          }
          _loadNotifications();
        } else {
          throw Exception(response['message'] ?? 'Không thể xóa thông báo');
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(context, 'Lỗi khi xóa thông báo: $e');
        }
      }
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          // FIX: Dùng scrollController từ DraggableScrollableSheet để bottom sheet scroll được
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const Text(
                    'Chi tiết thông báo',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notification['title'] ?? 'Không có tiêu đề',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Nội dung', notification['content'] ?? ''),
              _buildDetailRow(
                  'Loại thông báo', notification['typeNotification'] ?? ''),
              _buildDetailRow(
                  'Chế độ lịch',
                  _getModeDisplayName(
                      notification['schedule']?['mode'], notification)),
              _buildDetailRow(
                  'Thời gian tạo', _formatDateTime(notification['createdAt'])),
              _buildDetailRow('Cập nhật lần cuối',
                  _formatDateTime(notification['updatedAt'])),
              if (notification['schedule']?['sendAt'] != null)
                _buildDetailRow('Thời gian gửi',
                    _formatDateTime(notification['schedule']['sendAt'])),
              if (notification['lastSentAt'] != null)
                _buildDetailRow(
                    'Gửi lúc', _formatDateTime(notification['lastSentAt'])),
              if (notification['nextRunAt'] != null)
                _buildDetailRow(
                    'Lần gửi tiếp theo',
                    _formatDateTime(notification['nextRunAt'],
                        showRelative: false)),
              if (notification['activeJobId'] != null)
                _buildDetailRow('Job ID', notification['activeJobId']),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Expanded(
                  //   child: ElevatedButton.icon(
                  //     onPressed: () {
                  //       Navigator.pop(context);
                  //       _editNotification(notification);
                  //     },
                  //     icon: const Icon(Icons.edit),
                  //     label: const Text('Chỉnh sửa'),
                  //     style: ElevatedButton.styleFrom(
                  //       padding: const EdgeInsets.symmetric(vertical: 12),
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteNotification(
                            notification['_id'], notification['title']);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Xóa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _editNotification(Map<String, dynamic> notification) {
    context.push('/notification-edit', extra: notification);
  }

  void _createNewNotification() {
    context.push(AdminRouterConfig.createNotification);
  }

  void _showFilterBottomSheet() {
    // FIX: Khởi tạo temp variables với giá trị hiện tại trước khi build sheet
    String? tempSelectedType = selectedType;
    String? tempSelectedMode = selectedMode;
    String? tempSelectedStatus = selectedStatus;
    String tempSearchQuery = searchQuery;
    final TextEditingController tempSearchController =
    TextEditingController(text: searchQuery);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Lọc thông báo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search field
                  TextField(
                    controller: tempSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm kiếm',
                      hintText: 'Nhập tiêu đề hoặc nội dung',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      tempSearchQuery = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  // FIX: Type filter — value là String (type['value']), khớp với selectedType (String?)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Loại thông báo',
                      border: OutlineInputBorder(),
                    ),
                    value: tempSelectedType,
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('Tất cả')),
                      ...typeOfRecipient.map((type) => DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['name']!),
                      )),
                    ],
                    onChanged: (value) {
                      setStateSheet(() {
                        tempSelectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Mode filter
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Chế độ lịch',
                      border: OutlineInputBorder(),
                    ),
                    value: tempSelectedMode,
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('Tất cả')),
                      ...modeOptions.map((mode) => DropdownMenuItem<String>(
                        value: mode,
                        child: Text(_getModeText(mode)),
                      )),
                    ],
                    onChanged: (value) {
                      setStateSheet(() {
                        tempSelectedMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setStateSheet(() {
                              tempSearchQuery = '';
                              tempSearchController.clear();
                              tempSelectedType = null;
                              tempSelectedMode = null;
                              tempSelectedStatus = null;
                            });
                          },
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              searchQuery = tempSearchQuery;
                              _searchController.text = tempSearchQuery;
                              selectedType = tempSelectedType;
                              selectedMode = tempSelectedMode;
                              selectedStatus = tempSelectedStatus;
                              _applyFilters();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => tempSearchController.dispose());
  }

  // FIX: _getTypeText nhận String thay vì dynamic
  String _getTypeText(String? type) {
    switch (type) {
      case 'customer':
        return 'Khách hàng';
      case 'ktv':
        return 'Kỹ thuật viên';
      case 'staff':
        return 'Nhân viên';
      case 'all':
        return 'Tất cả';
      default:
        return type ?? 'Không xác định';
    }
  }

  String _getScheduleInfo(Map<String, dynamic> notification) {
    String mode = notification['schedule']?['mode'] ?? '';
    switch (mode) {
      case 'daily_time':
        if (notification['schedule']?['daysOfWeek'] != null &&
            (notification['schedule']['daysOfWeek'] as List).isNotEmpty) {
          return 'Lặp theo tuần - ${_formatVNTime(notification['schedule']?['timeOfDay'])}';
        }
        return 'Lặp theo ngày - ${_formatVNTime(notification['schedule']?['timeOfDay'])}';
      case 'interval':
        int interval = notification['schedule']?['repeatInterval'] ?? 0;
        int minutes = interval ~/ 60000;
        return 'Lặp sau mỗi $minutes phút';
      case 'once':
        return 'Gửi một lần';
      default:
        return 'Không xác định';
    }
  }

  String _formatVNTime(String? timeOfDay) {
    if (timeOfDay == null) return '';
    try {
      List<String> parts = timeOfDay.split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        return '$hour:${minute.toString().padLeft(2, '0')}';
      }
      return timeOfDay;
    } catch (e) {
      return timeOfDay;
    }
  }

  bool get _hasActiveFilters =>
      selectedType != null ||
          selectedMode != null ||
          selectedStatus != null ||
          searchQuery.isNotEmpty;

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
            const Text("Quản lý thông báo"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thông báo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      _searchController.clear();
                      _applyFilters();
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),

          // Filter chips
          if (selectedType != null || selectedMode != null || selectedStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (selectedType != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('Loại: ${_getTypeText(selectedType)}'),
                          onDeleted: () {
                            setState(() {
                              selectedType = null;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    if (selectedMode != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label:
                          Text('Chế độ: ${_getModeText(selectedMode)}'),
                          onDeleted: () {
                            setState(() {
                              selectedMode = null;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    if (selectedStatus != null)
                      Chip(
                        label: Text('Trạng thái: $selectedStatus'),
                        onDeleted: () {
                          setState(() {
                            selectedStatus = null;
                            _applyFilters();
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

          // FIX: Expanded + RefreshIndicator + ListView — không dùng ScrollController thêm.
          // physics: AlwaysScrollableScrollPhysics() đảm bảo pull-to-refresh hoạt động ngay cả khi danh sách ít item.
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredNotifications.isEmpty
                  ? ListView(
                // FIX: Dùng ListView thay vì Center để RefreshIndicator hoạt động khi list trống
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Không có thông báo nào',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedType = null;
                                selectedMode = null;
                                selectedStatus = null;
                                searchQuery = '';
                                _searchController.clear();
                                _applyFilters();
                              });
                            },
                            child: const Text('Xóa bộ lọc'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                // FIX: Không gắn ScrollController tùy chỉnh — để RefreshIndicator tự quản lý
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: filteredNotifications.length,
                itemBuilder: (context, index) {
                  final notification = filteredNotifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNotification,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showNotificationDetails(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification['title'] ?? 'Không có tiêu đề',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification['content'] ?? 'Không có nội dung',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getScheduleInfo(notification),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Lần tới: ${_formatDateTime(notification['nextRunAt'], showRelative: false)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Bottom row: type badge (left) + mode badge + action buttons (right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Loại thông báo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: notification['typeNotification'] == 'customer'
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: notification['typeNotification'] == 'customer'
                            ? Colors.green[200]!
                            : Colors.orange[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          notification['typeNotification'] == 'customer'
                              ? Icons.person_outline
                              : Icons.build_outlined,
                          size: 12,
                          color: notification['typeNotification'] == 'customer'
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTypeText(notification['typeNotification']),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: notification['typeNotification'] == 'customer'
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Mode badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Text(
                      _getModeDisplayName(
                          notification['schedule']?['mode'], notification),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  // SizedBox(
                  //   height: 32,
                  //   width: 32,
                  //   child: IconButton(
                  //     onPressed: () => _editNotification(notification),
                  //     icon: const Icon(Icons.edit_outlined, size: 18),
                  //     color: Colors.blue[600],
                  //     constraints: const BoxConstraints(),
                  //     padding: EdgeInsets.zero,
                  //     tooltip: 'Chỉnh sửa',
                  //   ),
                  // ),
                  // const SizedBox(width: 4),
                  SizedBox(
                    height: 32,
                    width: 32,
                    child: IconButton(
                      onPressed: () => _deleteNotification(
                          notification['_id'], notification['title']),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red[400],
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      tooltip: 'Xóa',
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}