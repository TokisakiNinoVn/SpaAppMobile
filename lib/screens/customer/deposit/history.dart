import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/screens/components/dashed_divider_component.dart';
import 'package:spa_app/services/deposit_service.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/notification_service.dart';
import '../../../helper/format_helper.dart';
import '../../../routes/config/customer_router_config.dart';

class HistoryDepositScreen extends StatefulWidget {
  @override
  State<HistoryDepositScreen> createState() => _HistoryDepositScreenState();
}

class _HistoryDepositScreenState extends State<HistoryDepositScreen> {
  final DepositService _depositService = DepositService();

  List<dynamic> _historyDepositList = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHistoryDeposit();
  }

  Future<void> _loadHistoryDeposit() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _depositService.historyDeposit();

      if (response['status'] == 'success') {
        setState(() {
          _historyDepositList = response['data']['deposits'] ?? [];
          appLog("history deposit: $_historyDepositList");
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải lịch sử nạp tiền');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading deposit history: $e');
    }
  }

  // void _showTransactionDetailBottomSheet(Map<String, dynamic> deposit) {
  //   final transaction = deposit['transaction'] as Map<String, dynamic>? ?? {};
  //   final histories = (transaction['history'] as List?) ?? [];
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => DraggableScrollableSheet(
  //       initialChildSize: 0.75,
  //       maxChildSize: 0.95,
  //       minChildSize: 0.5,
  //       builder: (_, controller) => Container(
  //         decoration: const BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(
  //             top: Radius.circular(24),
  //           ),
  //         ),
  //         child: SingleChildScrollView(
  //           controller: controller,
  //           padding: const EdgeInsets.only(bottom: 24),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // Handle
  //               Center(
  //                 child: Container(
  //                   margin: const EdgeInsets.only(top: 12),
  //                   width: 50,
  //                   height: 5,
  //                   decoration: BoxDecoration(
  //                     color: Colors.grey.shade300,
  //                     borderRadius: BorderRadius.circular(100),
  //                   ),
  //                 ),
  //               ),
  //
  //               // Header
  //               Padding(
  //                 padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
  //                 child: Row(
  //                   children: [
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           const Text(
  //                             'Chi tiết giao dịch',
  //                             style: TextStyle(
  //                               fontSize: 20,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => Navigator.pop(context),
  //                       icon: const Icon(Icons.close),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //
  //               const Divider(),
  //
  //               // Amount Card
  //               Container(
  //                 margin: const EdgeInsets.all(16),
  //                 padding: const EdgeInsets.all(20),
  //                 decoration: BoxDecoration(
  //                   color: Colors.green.withOpacity(.08),
  //                   borderRadius: BorderRadius.circular(16),
  //                 ),
  //                 child: Column(
  //                   children: [
  //                     Text(
  //                       '+ ${FormatHelper.formatPrice(transaction['amount'])}',
  //                       style: const TextStyle(
  //                         fontSize: 28,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.green,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 6),
  //                     Text(
  //                       _getTransactionTypeText(transaction['type']),
  //                       style: TextStyle(
  //                         color: Colors.grey.shade700,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //
  //               _buildSectionTitle('Thông tin giao dịch'),
  //
  //               _buildDetailRow(
  //                 'Mã giao dịch',
  //                 transaction['code'] ?? '--',
  //               ),
  //
  //               _buildDetailRow(
  //                 'Trạng thái',
  //                 _getStatusText(transaction['status']),
  //                 textColor: _getStatusColor(transaction['status']),
  //               ),
  //
  //               _buildDetailRow(
  //                 'Thời gian',
  //                 FormatHelper.formatDateTime(
  //                   transaction['createdAt'],
  //                 ),
  //               ),
  //
  //               const SizedBox(height: 20),
  //
  //               _buildSectionTitle('Thông tin số dư'),
  //
  //               _buildDetailRow(
  //                 'Số tiền giao dịch',
  //                 FormatHelper.formatPrice(
  //                   transaction['amount'],
  //                 ),
  //               ),
  //
  //               _buildDetailRow(
  //                 'Số dư sau giao dịch',
  //                 FormatHelper.formatPrice(
  //                   transaction['newBalance'],
  //                 ),
  //               ),
  //
  //               const SizedBox(height: 20),
  //
  //               _buildSectionTitle('Lịch sử xử lý'),
  //
  //               if (histories.isEmpty)
  //                 const Padding(
  //                   padding: EdgeInsets.all(16),
  //                   child: Text('Chưa có lịch sử xử lý'),
  //                 ),
  //
  //               ...List.generate(histories.length, (index) {
  //                 final item = histories[index];
  //
  //                 return _buildHistoryItem(
  //                   status: item['status'] ?? '',
  //                   message: item['message'] ?? '',
  //                   actor: item['actor'] ?? '',
  //                   timestamp: item['timestamp'],
  //                   details: item['details'],
  //                 );
  //               }),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  void _showTransactionDetailBottomSheet(Map<String, dynamic> deposit) {
    final transaction = deposit['transaction'] as Map<String, dynamic>? ?? {};
    final histories = (transaction['history'] as List?) ?? [];

    final status = transaction['status'] ?? '';
    final amount = transaction['amount'] ?? 0;

    final statusColor = _getStatusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        Widget infoRow(
            String title,
            String value, {
              Color? valueColor,
              bool copyable = false,
            }) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: valueColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (copyable)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Spacer(),
                        const Text(
                          'Chi tiết giao dịch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // const SizedBox(height: 24),

                  /// STATUS CARD
                  // Container(
                  //   margin: const EdgeInsets.symmetric(horizontal: 20),
                  //   padding: const EdgeInsets.all(20),
                  //   decoration: BoxDecoration(
                  //     color: statusColor.withOpacity(.08),
                  //     borderRadius: BorderRadius.circular(20),
                  //     border: Border.all(
                  //       color: statusColor.withOpacity(.2),
                  //     ),
                  //   ),
                  //   child: Column(
                  //     children: [
                  //       CircleAvatar(
                  //         radius: 30,
                  //         backgroundColor: statusColor.withOpacity(.15),
                  //         child: Icon(
                  //           status == 'success'
                  //               ? Icons.check_circle
                  //               : Icons.pending,
                  //           size: 36,
                  //           color: statusColor,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 14),
                  //       Text(
                  //         _getStatusText(status),
                  //         style: TextStyle(
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.bold,
                  //           color: statusColor,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 10),
                  //       Text(
                  //         FormatHelper.formatPrice(amount),
                  //         style: const TextStyle(
                  //           fontSize: 30,
                  //           fontWeight: FontWeight.w800,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // const SizedBox(height: 20),

                  /// THÔNG TIN GIAO DỊCH
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt_long_rounded),
                            SizedBox(width: 8),
                            Text(
                              'Thông tin giao dịch',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade200),

                        infoRow(
                          'Trạng thái',
                          _getStatusText(status),
                          copyable: false,
                        ),
                        const SizedBox(height: 16),

                        infoRow(
                          'Mã giao dịch',
                          transaction['code'] ?? '--',
                          copyable: true,
                        ),

                        Divider(color: Colors.grey.shade200),

                        infoRow(
                          'Loại',
                          _getTransactionTypeText(
                            transaction['type'],
                          ),
                        ),

                        Divider(color: Colors.grey.shade200),

                        infoRow(
                          'Số tiền',
                          FormatHelper.formatPrice(
                            transaction['amount'],
                          ),
                        ),

                        Divider(color: Colors.grey.shade200),

                        infoRow(
                          'Số dư mới',
                          FormatHelper.formatPrice(
                            transaction['newBalance'],
                          ),
                        ),

                        Divider(color: Colors.grey.shade200),

                        infoRow(
                          'Thời gian tạo',
                          FormatHelper.formatDateTime(
                            transaction['createdAt'],
                          ),
                        ),

                        Divider(color: Colors.grey.shade200),

                        infoRow(
                          'Cập nhật',
                          FormatHelper.formatDateTime(
                            transaction['updatedAt'],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// LỊCH SỬ
                  if (histories.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history),
                              SizedBox(width: 8),
                              Text(
                                'Lịch sử xử lý',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          ...List.generate(histories.length, (index) {
                            final item = histories[index];

                            return Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    if (index != histories.length - 1)
                                      Container(
                                        width: 2,
                                        height: 65,
                                        color: Colors.grey.shade300,
                                      ),
                                  ],
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Padding(
                                    padding:
                                    const EdgeInsets.only(
                                      bottom: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['message'] ?? '',
                                          style: const TextStyle(
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),

                                        // if (item['details'] != null)
                                        //   Padding(
                                        //     padding:
                                        //     const EdgeInsets.only(
                                        //       top: 4,
                                        //     ),
                                        //     child: Text(
                                        //       item['details'],
                                        //       style: TextStyle(
                                        //         color: Colors
                                        //             .grey.shade600,
                                        //         fontSize: 13,
                                        //       ),
                                        //     ),
                                        //   ),

                                        const SizedBox(height: 6),

                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            // Container(
                                            //   padding:
                                            //   const EdgeInsets
                                            //       .symmetric(
                                            //     horizontal: 8,
                                            //     vertical: 4,
                                            //   ),
                                            //   decoration:
                                            //   BoxDecoration(
                                            //     color: Colors.blue
                                            //         .withOpacity(
                                            //         .08),
                                            //     borderRadius:
                                            //     BorderRadius
                                            //         .circular(
                                            //         100),
                                            //   ),
                                            //   child: Text(
                                            //     item['actor'] ??
                                            //         'system',
                                            //     style:
                                            //     const TextStyle(
                                            //       fontSize: 12,
                                            //     ),
                                            //   ),
                                            // ),

                                            Text(
                                              FormatHelper
                                                  .formatDateTime(
                                                item['timestamp'],
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors
                                                    .grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'success':
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
      case 'success':
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
      case 'deposit':
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
      backgroundColor: ColorConfig.white,
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
              "Lịch sử nạp tiền",
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
              onPressed: _loadHistoryDeposit,
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
              'Chưa có lịch sử nạp tiền',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      itemCount: _historyDepositList.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final deposit = _historyDepositList[index];
        final transaction =
        deposit['transaction'] as Map<String, dynamic>;

        final statusColor =
        _getStatusColor(transaction['status']);

        return InkWell(
          onTap: () => _showTransactionDetailBottomSheet(deposit),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    transaction['status'] == 'success'
                        ? Icons.arrow_downward_rounded
                        : Icons.schedule_rounded,
                    color: statusColor,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Nạp tiền vào ví',
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),

                          Text(
                            '+${FormatHelper.formatPrice(transaction['amount'])}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        deposit['code'] ??
                            transaction['code'] ??
                            '--',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            _getStatusText(
                                transaction['status']),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),

                          const Spacer(),

                          Text(
                            FormatHelper.formatDateTime(
                              deposit['createdAt'],
                            ),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}