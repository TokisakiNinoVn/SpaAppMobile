import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/withdraw_service.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/notification_service.dart';
import '../../../helper/format_helper.dart';
import '../../../routes/config/customer_router_config.dart';

class HistoryWithdrawScreen extends StatefulWidget {
  @override
  State<HistoryWithdrawScreen> createState() => _HistoryWithdrawScreenState();
}

class _HistoryWithdrawScreenState extends State<HistoryWithdrawScreen> {
  final WithdrawService _withdrawService = WithdrawService();

  List<dynamic> _historyDepositList = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHistoryWithdraw();
  }

  Future<void> _loadHistoryWithdraw() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _withdrawService.historyWithdraw();
      // appLog("Response: $response");

      if (response['status'] == 'success') {
        setState(() {
          _historyDepositList = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải lịch sử rút tiền');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading withdraw history: $e');
    }
  }

  void _showTransactionDetailBottomSheet(
      Map<String, dynamic> withdraw,
      ) {
    final transaction =
    (withdraw['transaction'] ?? {}) as Map<String, dynamic>;

    final bankInfor =
    (withdraw['bankInfor'] ?? {}) as Map<String, dynamic>;

    final history =
    (transaction['history'] ?? []) as List<dynamic>;

    final status = withdraw['status'] ?? 'pending';

    final statusColor = _getStatusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // ===== HANDLE =====
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),

                  // ===== HEADER =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      16,
                      16,
                      12,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Chi tiết giao dịch",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(99),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(99),
                            ),
                            child: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          // =================================================
                          // STATUS CARD
                          // =================================================
                          // Container(
                          //   width: double.infinity,
                          //   padding: const EdgeInsets.all(22),
                          //   decoration: BoxDecoration(
                          //     gradient: LinearGradient(
                          //       colors: [
                          //         statusColor,
                          //         statusColor.withOpacity(.75),
                          //       ],
                          //     ),
                          //     borderRadius:
                          //     BorderRadius.circular(24),
                          //     boxShadow: [
                          //       BoxShadow(
                          //         color: statusColor.withOpacity(
                          //           .25,
                          //         ),
                          //         blurRadius: 18,
                          //         offset: const Offset(0, 8),
                          //       ),
                          //     ],
                          //   ),
                          //   child: Column(
                          //     children: [
                          //       Container(
                          //         width: 74,
                          //         height: 74,
                          //         decoration: BoxDecoration(
                          //           color: Colors.white
                          //               .withOpacity(.15),
                          //           shape: BoxShape.circle,
                          //         ),
                          //         child: const Icon(
                          //           Icons
                          //               .account_balance_wallet_rounded,
                          //           color: Colors.white,
                          //           size: 38,
                          //         ),
                          //       ),
                          //
                          //       const SizedBox(height: 18),
                          //
                          //       Text(
                          //         FormatHelper.formatPrice(
                          //           withdraw['amount'],
                          //         ),
                          //         style: const TextStyle(
                          //           color: Colors.white,
                          //           fontSize: 32,
                          //           fontWeight: FontWeight.bold,
                          //         ),
                          //       ),
                          //
                          //       const SizedBox(height: 10),
                          //
                          //       Container(
                          //         padding:
                          //         const EdgeInsets.symmetric(
                          //           horizontal: 14,
                          //           vertical: 7,
                          //         ),
                          //         decoration: BoxDecoration(
                          //           color: Colors.white
                          //               .withOpacity(.18),
                          //           borderRadius:
                          //           BorderRadius.circular(
                          //             999,
                          //           ),
                          //         ),
                          //         child: Text(
                          //           _getStatusText(status),
                          //           style: const TextStyle(
                          //             color: Colors.white,
                          //             fontWeight:
                          //             FontWeight.w600,
                          //           ),
                          //         ),
                          //       ),
                          //
                          //       const SizedBox(height: 18),
                          //
                          //       Row(
                          //         children: [
                          //           Expanded(
                          //             child: _buildMiniInfo(
                          //               "Phí",
                          //               FormatHelper
                          //                   .formatPrice(
                          //                 withdraw['fee'],
                          //               ),
                          //             ),
                          //           ),
                          //           const SizedBox(width: 12),
                          //           Expanded(
                          //             child: _buildMiniInfo(
                          //               "Thực nhận",
                          //               FormatHelper
                          //                   .formatPrice(
                          //                 withdraw[
                          //                 'netAmount'],
                          //               ),
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          //
                          // const SizedBox(height: 20),

                          // =================================================
                          // THÔNG TIN GIAO DỊCH
                          // =================================================
                          _buildSectionCard(
                            title: "Thông tin giao dịch",
                            icon:
                            Icons.receipt_long_rounded,
                            children: [
                              _buildDetailRow(
                                "Mã rút tiền",
                                withdraw['code'] ?? '--',
                                copyable: true,
                              ),
                              // _buildDetailRow(
                              //   "ID giao dịch",
                              //   transaction['_id'] ??
                              //       '--',
                              //   copyable: true,
                              // ),
                              // _buildDetailRow(
                              //   "Loại",
                              //   _getTransactionTypeText(
                              //     transaction['type'],
                              //   ),
                              // ),
                              _buildDetailRow(
                                "Trạng thái",
                                _getStatusText(status),
                                valueColor: statusColor,
                              ),
                              _buildDetailRow(
                                "Số tiền rút",
                                FormatHelper.formatPrice(
                                  withdraw['amount'],
                                ),
                              ),
                              _buildDetailRow(
                                "Phí giao dịch",
                                FormatHelper.formatPrice(
                                  withdraw['fee'],
                                ),
                                valueColor: Colors.red,
                              ),
                              _buildDetailRow(
                                "Số tiền nhận",
                                FormatHelper.formatPrice(
                                  withdraw['netAmount'],
                                ),
                                valueColor:
                                Colors.green,
                              ),
                              _buildDetailRow(
                                "Số dư mới",
                                FormatHelper.formatPrice(
                                  transaction[
                                  'newBalance'],
                                ),
                              ),
                              _buildDetailRow(
                                "Ngày tạo",
                                FormatHelper
                                    .formatDateTime(
                                  withdraw['createdAt'],
                                ),
                              ),
                              // _buildDetailRow(
                              //   "Cập nhật",
                              //   FormatHelper
                              //       .formatDateTime(
                              //     withdraw['updatedAt'],
                              //   ),
                              // ),
                              _buildDetailRow(
                                "Xử lý lúc",
                                withdraw['processedAt'] ==
                                    null
                                    ? '--'
                                    : FormatHelper
                                    .formatDateTime(
                                  withdraw[
                                  'processedAt'],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // =================================================
                          // THÔNG TIN NGÂN HÀNG
                          // =================================================
                          _buildSectionCard(
                            title:
                            "Thông tin tài khoản",
                            icon:
                            Icons.account_balance,
                            children: [
                              _buildDetailRow(
                                "Ngân hàng",
                                (bankInfor['bankName'] ??
                                    '--')
                                    .toString()
                                    .toUpperCase(),
                              ),
                              _buildDetailRow(
                                "Số tài khoản",
                                bankInfor[
                                'accountNumber'] ??
                                    '--',
                                copyable: true,
                              ),
                              _buildDetailRow(
                                "Chủ tài khoản",
                                bankInfor[
                                'accountHolder'] ??
                                    '--',
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // =================================================
                          // HISTORY
                          // =================================================
                          if (history.isNotEmpty)
                            _buildSectionCard(
                              title:
                              "Lịch sử giao dịch",
                              icon:
                              Icons.history_rounded,
                              children: [
                                ...history.map((item) {
                                  return Container(
                                    margin:
                                    const EdgeInsets
                                        .only(
                                      bottom: 16,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              width: 14,
                                              height: 14,
                                              decoration:
                                              BoxDecoration(
                                                color:
                                                _getStatusColor(
                                                  item[
                                                  'status'],
                                                ),
                                                shape: BoxShape
                                                    .circle,
                                              ),
                                            ),
                                            Container(
                                              width: 2,
                                              height: 60,
                                              color: Colors
                                                  .grey
                                                  .shade300,
                                            ),
                                          ],
                                        ),

                                        const SizedBox(
                                          width: 14,
                                        ),

                                        Expanded(
                                          child: Container(
                                            padding:
                                            const EdgeInsets
                                                .all(
                                              14,
                                            ),
                                            decoration:
                                            BoxDecoration(
                                              color: Colors
                                                  .grey
                                                  .shade50,
                                              borderRadius:
                                              BorderRadius
                                                  .circular(
                                                16,
                                              ),
                                              border:
                                              Border.all(
                                                color: Colors
                                                    .grey
                                                    .shade200,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                      Text(
                                                        item[
                                                        'status'] ??
                                                            '',
                                                        style:
                                                        TextStyle(
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          color:
                                                          _getStatusColor(
                                                            item['status'],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      FormatHelper
                                                          .formatDateTime(
                                                        item[
                                                        'timestamp'],
                                                      ),
                                                      style:
                                                      TextStyle(
                                                        fontSize:
                                                        12,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(
                                                  height:
                                                  10,
                                                ),

                                                Text(
                                                  item['message'] ??
                                                      '',
                                                  style:
                                                  const TextStyle(
                                                    height:
                                                    1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String title,
      String value, {
        Color? valueColor,
        bool copyable = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color:
                      valueColor ??
                          Colors.black87,
                    ),
                  ),
                ),

                if (copyable) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: value),
                      );

                      SnackBarHelper.showSuccess(
                        context,
                        "Đã sao chép",
                      );
                    },
                    borderRadius:
                    BorderRadius.circular(99),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(
      String title,
      String value,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Thành công';
      case 'pending':
        return 'Đang xử lý';
      case 'failed':
        return 'Thất bại';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.black87;
    }
  }

  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'withdraw':
        return 'Nạp tiền';
      case 'withdraw':
        return 'Rút tiền';
      case 'payment':
        return 'Thanh toán';
      default:
        return type;
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
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Lịch sử rút tiền",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistoryWithdraw,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_historyDepositList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử rút tiền',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyDepositList.length,
      itemBuilder: (context, index) {
        final withdraw = _historyDepositList[index];
        final transaction = withdraw as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ColorConfig.white,
            ),
            child: InkWell(
              onTap: () => _showTransactionDetailBottomSheet(withdraw),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            withdraw['code'] ?? transaction['code'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(transaction['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(transaction['status']),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(transaction['status']),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Số tiền: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          FormatHelper.formatPrice(transaction['netAmount']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thời gian:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          FormatHelper.formatDateTime(withdraw['createdAt']),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}