import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/services/user_service.dart';

class EditAddressScreen extends StatefulWidget {
  const EditAddressScreen({
    super.key,
  });

  @override
  State<EditAddressScreen> createState() =>  _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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

            //TODO: nút thêm mới địa chỉ
          ],
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Danh sách các địa chỉ của bạn")
        ],
      ),
    );
  }
}
