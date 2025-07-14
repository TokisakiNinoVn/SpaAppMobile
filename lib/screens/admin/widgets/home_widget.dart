import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  final String role;

  const HomeTab({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // const CircleAvatar(
          //   radius: 40,
          //   backgroundImage: AssetImage('lib/assets/images/img.png'),
          // ),
          const SizedBox(height: 20),
          Text(
            'Phân quyền: $role',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}