import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/user_discount_service.dart';

class ManagementPostOrder extends StatefulWidget {

  const ManagementPostOrder({
    super.key,
  });

  @override
  State<ManagementPostOrder> createState() =>  _ManagementPostOrderState();
}

class _ManagementPostOrderState extends State<ManagementPostOrder> {
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
            const Text("Quản lý đăng việc"),
          ],
        ),
      ),

      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                context.push(AdminRouterConfig.createOrderPost);
              },
              child: Text("Tạo bài đăng việc mới")
            )
          ],
        ),
      ),
    );
  }
}
