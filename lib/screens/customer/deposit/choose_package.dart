import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';

import '../../../storage/index.dart';

class ChoosePackage extends StatefulWidget {
  const ChoosePackage({super.key});

  @override
  State<ChoosePackage> createState() => _ChoosePackageState();
}

class _ChoosePackageState extends State<ChoosePackage> {
  final List<int> amounts = [10000, 20000, 50000, 100000, 200000, 500000];
  bool _isLoading = false;
  String _errorMessage = '';
  int nowBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadBalanceNow();
  }

  Future<void> _loadBalanceNow() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final balance = await SharedPrefs.getValue(PrefType.int, "balance");

      setState(() {
        nowBalance = balance ?? 0;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error get now balance: $e');
    }
  }

  void _showConfirmBottomSheet(int amount) {
    String selectedPaymentMethod = 'Chuyển khoản';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Xác nhận nạp tiền',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 8),

              // Amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  '${FormatHelper.formatPrice((amount))} VND',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Số tiền sẽ được cộng vào ví của bạn',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 24),

              // Current balance display
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFF5F5F5),
              //     borderRadius: BorderRadius.circular(16),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       const Text(
              //         'Số dư ví hiện tại:',
              //         style: TextStyle(
              //           fontSize: 14,
              //           fontWeight: FontWeight.w500,
              //           color: Color(0xFF1A1A1A),
              //         ),
              //       ),
              //       Text(
              //         '${FormatHelper.formatPrice(nowBalance)} VND',
              //         style: const TextStyle(
              //           fontSize: 16,
              //           fontWeight: FontWeight.w700,
              //           color: Color(0xFF1A1A1A),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              //
              // const SizedBox(height: 24),

              // Payment Methods section
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Radio button options
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Chuyển khoản'),
                      value: 'Chuyển khoản',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                      activeColor: ColorConfig.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    RadioListTile<String>(
                      title: const Text('Thanh toán qua thẻ ATM'),
                      value: 'Thanh toán qua thẻ ATM',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                          _showUnsupportedPaymentMethod(context);
                          Navigator.pop(context);
                        });
                      },
                      activeColor: ColorConfig.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    RadioListTile<String>(
                      title: const Text('Thẻ Visa/MasterCard'),
                      value: 'Thẻ Visa/MasterCard',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                          _showUnsupportedPaymentMethod(context);
                          Navigator.pop(context);
                        });
                      },
                      activeColor: ColorConfig.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCCCCCC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedPaymentMethod == 'Chuyển khoản') {
                          Navigator.pop(context);
                          context.go('${CustomerRouterConfig.qrDeposit}/$amount');
                        } else {
                          _showUnsupportedPaymentMethod(context);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: ColorConfig.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnsupportedPaymentMethod(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phương thức thanh toán không được hỗ trợ'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onSelectAmount(int amount) {
    _showConfirmBottomSheet(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Chọn gói nạp",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.history_outlined, color: Color(0xFF1A1A1A), size: 22),
              tooltip: 'Lịch sử nạp',
              onPressed: () {
                context.go(CustomerRouterConfig.historyDeposit);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header icon section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số dư hiện tại',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        FormatHelper.formatPrice(nowBalance),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: ColorConfig.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Chọn số tiền bạn muốn nạp',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF777777),
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),

          // Package list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: amounts.length,
              itemBuilder: (context, index) {
                final amount = amounts[index];
                final isLast = index == amounts.length - 1;

                return GestureDetector(
                  onTap: () => _onSelectAmount(amount),
                  child: Container(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: const Color(0xFFF5F5F5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                Icons.attach_money_rounded,
                                size: 20,
                                color: ColorConfig.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${FormatHelper.formatPrice(amount)} VND",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Color(0xFF999999),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}