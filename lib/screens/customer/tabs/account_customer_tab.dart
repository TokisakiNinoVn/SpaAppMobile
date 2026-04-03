import 'package:flutter/material.dart';

class ActivityCustomerTab extends StatelessWidget {
  const ActivityCustomerTab({super.key});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hi!! Activity tab customer")
        ],
      ),
    );
  }
}
