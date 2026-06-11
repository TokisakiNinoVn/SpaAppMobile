import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/providers/user_provider.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/routes/config/technician_router_config.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../storage/index.dart';

class CreateRequestWithdrawTechnician extends StatefulWidget {
  const CreateRequestWithdrawTechnician({super.key});

  @override
  State<CreateRequestWithdrawTechnician> createState() => _CreateRequestWithdrawTechnicianState();
}

class _CreateRequestWithdrawTechnicianState extends State<CreateRequestWithdrawTechnician> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  bool _saveBankInfo = false;
  bool _isLoading = false;
  bool _isLoadingSavedInfo = true;
  String _errorMessage = '';
  int nowBalance = 0;
  int? newBalance;

  // Constants
  static const int minWithdrawAmount = 10000;
  int maxWithdrawAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedBankInfo();
    _setupAmountListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalanceNow();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _setupAmountListener() {
    _amountController.addListener(() {
      final text = _amountController.text;
      if (text.isNotEmpty) {
        final cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanText.isNotEmpty) {
          final number = int.parse(cleanText);
          final formatted = FormatHelper.formatPrice(number);
          if (_amountController.text != formatted) {
            final cursorPosition = _amountController.selection.baseOffset;
            _amountController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
          // ===== THÊM ĐOẠN NÀY =====
          // Cập nhật số dư mới
          final amount = int.parse(cleanText);
          setState(() {
            newBalance = nowBalance - amount;
          });
        } else {
          setState(() {
            newBalance = null;
          });
        }
      } else {
        setState(() {
          newBalance = null;
        });
      }
    });
  }

  Future<void> _loadBalanceNow() async {
    final provider = context.read<UserProvider>();
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await provider.loadBalanceUser();
      nowBalance = provider.nowBalance;

      setState(() {
        nowBalance = nowBalance;
        maxWithdrawAmount = nowBalance;
        newBalance = nowBalance;
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

  Future<void> _loadSavedBankInfo() async {
    setState(() => _isLoadingSavedInfo = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final bankName = prefs.getString('saved_bank_name');
      final accountNumber = prefs.getString('saved_account_number');
      final accountHolder = prefs.getString('saved_account_holder');
      final saveInfo = prefs.getBool('save_bank_info') ?? false;

      if (saveInfo && bankName != null && accountNumber != null && accountHolder != null) {
        setState(() {
          _bankNameController.text = bankName;
          _accountNumberController.text = accountNumber;
          _accountHolderController.text = accountHolder;
          _saveBankInfo = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved bank info: $e');
    } finally {
      setState(() => _isLoadingSavedInfo = false);
    }
  }

  Future<void> _saveBankInfoToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_saveBankInfo) {
        await prefs.setString('saved_bank_name', _bankNameController.text.trim());
        await prefs.setString('saved_account_number', _accountNumberController.text.trim());
        await prefs.setString('saved_account_holder', _accountHolderController.text.trim());
        await prefs.setBool('save_bank_info', true);
      } else {
        await prefs.remove('saved_bank_name');
        await prefs.remove('saved_account_number');
        await prefs.remove('saved_account_holder');
        await prefs.setBool('save_bank_info', false);
      }
    } catch (e) {
      debugPrint('Error saving bank info: $e');
    }
  }

  void _setAmount(int amount) {
    setState(() {
      _amountController.text = FormatHelper.formatPrice(amount);
    });
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số tiền';
    }

    final cleanText = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return 'Số tiền không hợp lệ';
    }

    final amount = int.parse(cleanText);

    if (amount < minWithdrawAmount) {
      return 'Số tiền thanh toán tối thiểu là ${FormatHelper.formatPrice(minWithdrawAmount)}';
    }

    if (amount > maxWithdrawAmount) {
      return 'Số tiền thanh toán không được vượt quá số dư hiện tại (${FormatHelper.formatPrice(maxWithdrawAmount)})';
    }

    return null;
  }

  void _handleConfirm() {
    if (_formKey.currentState!.validate()) {
      // Get clean amount without formatting
      final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');

      // Save bank info if checkbox is checked
      _saveBankInfoToPrefs();

      // Navigate to ConfirmRequestWithdraw with all data
      context.push(
        TechnicianRouterConfig.confirmRequestWithdraw,
        extra: {
          'amount': cleanAmount,
          'bankName': _bankNameController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
          'accountHolder': _accountHolderController.text.trim(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConfig.primaryBackground,
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
                "Tạo yêu cầu thanh toán",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.history_outlined, color: Color(0xFF1A1A1A), size: 22),
              tooltip: 'Lịch sử thanh toán',
              onPressed: () {
                context.push(TechnicianRouterConfig.historyWithdraw);
              },
            ),
          ],
        ),
      ),
      body: _isLoadingSavedInfo
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Balance Card
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFF5F5F5),
              //     borderRadius: BorderRadius.circular(16),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       const Text(
              //         'Số dư hiện tại',
              //         style: TextStyle(
              //           fontSize: 12,
              //           color: Color(0xFF777777),
              //         ),
              //       ),
              //       const SizedBox(height: 6),
              //       Text(
              //         FormatHelper.formatPrice(nowBalance),
              //         style: TextStyle(
              //           fontSize: 22,
              //           fontWeight: FontWeight.w700,
              //           color: ColorConfig.primary,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // Current Balance Row (2 cột)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Cột trái: Số dư hiện tại
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng thu nhập hiện tại',
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

                    // Icon mũi tên ở giữa
                    if (newBalance != null && _amountController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorConfig.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 22,
                          color: ColorConfig.primary,
                        ),
                      ),

                    // Cột phải: Số dư mới
                    if (newBalance != null && _amountController.text.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Số dư mới',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF777777),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              FormatHelper.formatPrice(newBalance!),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: ColorConfig.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // Amount Field with Range
              _buildAmountField(),

              const SizedBox(height: 5),

              // Bank Name Field
              _buildFormField(
                label: 'Tên ngân hàng',
                hint: 'Ví dụ: Vietcombank, Techcombank, ...',
                controller: _bankNameController,
                prefixIcon: Icons.account_balance_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên ngân hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 5),

              // Account Number Field
              _buildFormField(
                label: 'Số tài khoản',
                hint: 'Nhập số tài khoản ngân hàng',
                controller: _accountNumberController,
                prefixIcon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tài khoản';
                  }
                  if (value.length < 8) {
                    return 'Số tài khoản không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 5),

              // Account Holder Field
              _buildFormField(
                label: 'Chủ tài khoản',
                hint: 'Nhập tên chủ tài khoản',
                controller: _accountHolderController,
                prefixIcon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên chủ tài khoản';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Save Bank Info Checkbox
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _saveBankInfo,
                        onChanged: (bool? value) {
                          setState(() {
                            _saveBankInfo = value ?? false;
                          });
                        },
                        activeColor: ColorConfig.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Lưu thông tin ngân hàng cho lần sau',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConfig.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // row url "Hỗ trợ" và  " Chính sách và điều khoản"
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(AppConfig.urlSupport)),
                    child: Text(
                      'Hỗ trợ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConfig.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Text(
                    ' | ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorConfig.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(AppConfig.urlTerm)),
                    child: Text(
                      'Chính sách và điều khoản',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConfig.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Số tiền yêu cầu thanh toán',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE8ECF0),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              hintText: 'Nhập số tiền cần rút',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade400,
              ),
              prefixIcon: const Icon(
                Icons.attach_money_rounded,
                size: 22,
                color: Color(0xFF8E9AAB),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: _validateAmount,
          ),
        ),
        const SizedBox(height: 12),
        // Amount range hint with clickable amounts
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFF8E9AAB),
              ),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  children: [
                    const TextSpan(text: 'Có thể rút: '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _setAmount(minWithdrawAmount),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorConfig.textPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            FormatHelper.formatPrice(minWithdrawAmount),
                            style: TextStyle(
                              color: ColorConfig.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' - '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _setAmount(maxWithdrawAmount),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorConfig.textPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            FormatHelper.formatPrice(maxWithdrawAmount),
                            style: TextStyle(
                              color: ColorConfig.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' VNĐ'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE8ECF0),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 22,
                color: const Color(0xFF8E9AAB),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}