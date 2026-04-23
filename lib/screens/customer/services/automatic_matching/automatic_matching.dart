import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/service_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/notification_service.dart';
import '../../../../helper/format_helper.dart';
import '../../../../routes/config/customer_router_config.dart';

class AutomaticMatchingScreen extends StatefulWidget {
  @override
  State<AutomaticMatchingScreen> createState() => _AutomaticMatchingScreenState();
}

class _AutomaticMatchingScreenState extends State<AutomaticMatchingScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final NotificationService _notificationService = NotificationService();
  final ServiceService _serviceService = ServiceService();

  List<dynamic>? allServices = [];

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


  @override
  void initState() {
    super.initState();
    _loadAllServices();
  }

  Future<void> _loadAllServices() async {
    try {
      final response = await _serviceService.listService();
      appLog('List service: $response');
      setState(() {
        allServices = response['data'];
      });
    } catch (e) {
      print("Error loading services: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: ColorConfig.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Ghép tự động",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConfig.textBlack,
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