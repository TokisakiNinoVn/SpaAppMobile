import 'package:flutter/material.dart';

class HomeCustomerTab extends StatelessWidget {
  const HomeCustomerTab({super.key});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hi!! home tab customer")
        ],
      ),
    );
  }
}
