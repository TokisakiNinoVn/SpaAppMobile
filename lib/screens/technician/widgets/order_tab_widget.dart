import 'package:flutter/material.dart';

class OrderTab extends StatefulWidget {
  const OrderTab({super.key});

  @override
  State<OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<OrderTab> {
  int selectedTab = 0; // 0: Đơn đang có, 1: Đơn đặt trước

  final List<Map<String, String>> currentOrders = [
    {'id': '001', 'name': 'Khách A', 'time': 'Ngay bây giờ'},
    {'id': '002', 'name': 'Khách B', 'time': 'Đang chờ'},
  ];

  final List<Map<String, String>> scheduledOrders = [
    {'id': '101', 'name': 'Khách C', 'time': '18:00'},
    {'id': '102', 'name': 'Khách D', 'time': '20:30'},
  ];

  @override
  Widget build(BuildContext context) {
    final orders =
    selectedTab == 0 ? currentOrders : scheduledOrders;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            const Text(
              'List Order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Toggle buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabButton("Yêu cầu đơn mới", 0),
                  const SizedBox(width: 12),
                  _buildTabButton("Đơn đặt trước", 1),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderItem(order);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, String> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Mã: ${order['id']}"),
          Text(order['name'] ?? ''),
          Text(order['time'] ?? ''),
        ],
      ),
    );
  }
}
