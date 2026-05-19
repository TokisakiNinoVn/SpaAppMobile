import 'package:flutter/material.dart';

class PolicyTabWidget extends StatelessWidget {
  const PolicyTabWidget({super.key});

  final List<Map<String, String>> policyItems = const [
    {
      'title': '1. Giờ làm việc',
      'content':
      'Kỹ thuật viên làm việc theo ca đã đăng ký. Vui lòng tuân thủ thời gian làm việc và thông báo trước nếu có thay đổi.',
    },
    {
      'title': '2. Quy định trang phục',
      'content':
      'Trang phục phải luôn sạch sẽ, đồng phục đúng quy định và đeo thẻ nhân viên trong suốt thời gian làm việc.',
    },
    {
      'title': '3. Hành vi chuyên nghiệp',
      'content':
      'Luôn giữ thái độ lịch sự, chuyên nghiệp với khách hàng. Tuyệt đối không được có hành vi xúc phạm hay thiếu tôn trọng.',
    },
    {
      'title': '4. Chính sách lương thưởng',
      'content':
      'Lương được chi trả vào ngày 5 hàng tháng. Các khoản thưởng sẽ được tổng kết và thanh toán vào cuối tháng.',
    },
    {
      'title': '5. Nghỉ phép và báo vắng',
      'content':
      'Kỹ thuật viên cần thông báo ít nhất 1 ngày trước khi nghỉ phép hoặc không thể đến làm việc để sắp xếp thay ca.',
    },
    {
      'title': '6. Bảo mật thông tin',
      'content':
      'Không được tiết lộ thông tin cá nhân của khách hàng hoặc dữ liệu nội bộ ra bên ngoài dưới bất kỳ hình thức nào.',
    },
  ];

  Widget _buildPolicyItem(String title, String content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

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
                  'Chính sách & Điều khoản',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              ...policyItems.map((item) => _buildPolicyItem(item['title']!, item['content']!)),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Cảm ơn bạn đã tuân thủ các chính sách của Serena Spa!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
