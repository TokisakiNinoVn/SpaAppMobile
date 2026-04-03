import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/technician_service.dart';

import '../../../routes/config/customer_router_config.dart';

class ListDetailsNotificationScreen extends StatefulWidget {
  @override
  State<ListDetailsNotificationScreen> createState() => _ListDetailsNotificationScreenState();
}

class _ListDetailsNotificationScreenState extends State<ListDetailsNotificationScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final LikeService _likeService = LikeService();

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFavorite = false;
  Map<String, dynamic>? _selectedService;
  int? _selectedTimeIndex;
  bool _showBookingBottomSheet = false;

  // State management
  Map<String, dynamic>? _technicianDetails;
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
    _loadTechnicianDetails();
  }

  Future<void> _loadTechnicianDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // final response = await _technicianService.getDetailsTechnicianForCustomerService(widget.id);
      //
      // if (response['success'] == true) {
      //   setState(() {
      //     _technicianDetails = response['data'];
      //     _isLoading = false;
      //   });
      // } else {
      //   throw Exception(response['message'] ?? 'Không thể tải thông tin kỹ thuật viên');
      // }
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
        body: const Center(
          child: Center(
            child: Text("List notification"),
          )
        ),
      );
  }
}