import 'package:flutter/material.dart';

class JobApplicationTab extends StatelessWidget {
  const JobApplicationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Chức năng đang được phát triển thêm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
