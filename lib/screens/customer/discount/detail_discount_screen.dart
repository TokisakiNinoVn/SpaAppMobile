import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';

class DetailDiscountScreen extends StatefulWidget {

  const DetailDiscountScreen({
    super.key,
  });

  @override
  State<DetailDiscountScreen> createState() =>  _DetailDiscountScreenState();
}

class _DetailDiscountScreenState extends State<DetailDiscountScreen> {
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorConfig.white,
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
