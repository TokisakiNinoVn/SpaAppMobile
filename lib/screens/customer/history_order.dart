import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HistoryOrderScreen extends StatelessWidget {
  const HistoryOrderScreen({super.key});

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
            const Text("Lịch sử hóa đơn"),
          ],
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(onPressed: () {
            context.go('/home-customer/list-technician/detail-technician/create-order-technician');

          }, child: Text("Tạo hóa đơn"))
        ],
      ),
    );
  }
}
