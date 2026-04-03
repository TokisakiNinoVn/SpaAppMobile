import 'package:flutter/material.dart';

class ListTechnicianScreen extends StatelessWidget {
  const ListTechnicianScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Danh sách các kỹ thuật viên")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hi!! Account tab customer")
        ],
      ),
    );
  }
}
