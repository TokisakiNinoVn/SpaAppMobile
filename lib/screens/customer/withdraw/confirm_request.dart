import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/services/user_discount_service.dart';

class CreateRequestWithdraw extends StatefulWidget {

  const CreateRequestWithdraw({
    super.key,
  });

  @override
  State<CreateRequestWithdraw> createState() =>  _CreateRequestWithdrawState();
}

class _CreateRequestWithdrawState extends State<CreateRequestWithdraw> {
  final UserDiscountService _userDiscountService = UserDiscountService();

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
            const Text("Yêu thích"),
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
