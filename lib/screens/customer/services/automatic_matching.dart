import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/notification_service.dart';
import '../../../helper/format_helper.dart';
import '../../../routes/config/customer_router_config.dart';

class AutomaticMatchingScreen extends StatefulWidget {
  @override
  State<AutomaticMatchingScreen> createState() => _AutomaticMatchingScreenState();
}

class _AutomaticMatchingScreenState extends State<AutomaticMatchingScreen> {
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
    // _loadListNotification();
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
                "Ghép tự động",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            children: [
              Text("Chức năng đang được phát triển!")
            ],
          ),
        ),
      );
  }
}