import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/services/user_discount_service.dart';

class ViewRateScreen extends StatefulWidget {

  const ViewRateScreen({
    super.key,
  });

  @override
  State<ViewRateScreen> createState() =>  _ViewRateScreenState();
}

class _ViewRateScreenState extends State<ViewRateScreen> {
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
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text("Đánh giá đơn việc"),
          ],
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Chức năng đang phát triển")
        ],
      ),
    );
  }
}
