import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/services/information_service.dart';
import 'package:spa_app/services/user_discount_service.dart';

class ListFeatureService extends StatefulWidget {

  const ListFeatureService({
    super.key,
  });

  @override
  State<ListFeatureService> createState() =>  _ListFeatureServiceState();
}

class _ListFeatureServiceState extends State<ListFeatureService> {
  final InformationService _informationService = InformationService();

  void initState() {
    super.initState();
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
            const Text("Hiển thị dịch vụ"),
          ],
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Danh sách Kỹ thuật viên yêu thích!")
        ],
      ),
    );
  }
}
