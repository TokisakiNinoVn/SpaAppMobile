import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../helper/logger_utils.dart';

class CreateOrderTechnicianScreen extends StatefulWidget {
  final dynamic data;

  const CreateOrderTechnicianScreen({
    super.key,
    required this.data,
  });

  @override
  State<CreateOrderTechnicianScreen> createState() =>
      _CreateOrderTechnicianScreenState();
}

class _CreateOrderTechnicianScreenState
    extends State<CreateOrderTechnicianScreen> {
  @override
  void initState() {
    super.initState();
    appLog("CreateOrderTechnicianScreen data: ", data: widget.data);
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
            // Nút back custom
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Tạo đơn",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                context.go('/home-customer/detail-technician');
              },
              child: const Text("Hoàn tất"),
            ),
          ],
        ),
      ),
    );
  }
}
