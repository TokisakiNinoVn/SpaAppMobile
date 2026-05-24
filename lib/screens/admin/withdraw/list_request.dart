import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/withdraw_service.dart';
import '../../../helper/format_helper.dart';

class ListRequestWithdraw extends StatefulWidget {
  @override
  State<ListRequestWithdraw> createState() => _ListRequestWithdrawState();
}

class _ListRequestWithdrawState extends State<ListRequestWithdraw> {
  final WithdrawService _withdrawService = WithdrawService();

  List<dynamic> _withdrawals = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Filter states
  String _selectedStatus = 'pending'; // mặc định pending
  final Set<String> _selectedRoles = {'customer', 'technician'}; // mặc định cả hai

  @override
  void initState() {
    super.initState();
    _loadListRequestWithdraw();
  }

  // Xây dựng query string từ filter hiện tại
  String _buildQueryString() {
    final params = <String>[];
    params.add('status=$_selectedStatus');
    if (_selectedRoles.isNotEmpty) {
      params.add('role=${_selectedRoles.join(',')}');
    }
    return params.join('&');
  }

  // Gọi API với query string hiện tại
  Future<void> _loadListRequestWithdraw() async {
    final query = _buildQueryString();
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _withdrawService.listRequestWithdraw(query);

      if (response['status'] == 'success') {
        setState(() {
          // Dựa trên cấu trúc API mẫu: data là mảng các yêu cầu
          _withdrawals = response['data'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải danh sách yêu cầu rút tiền');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading withdraw requests: $e');
    }
  }

  // Hiển thị BottomSheet lọc
  void _showFilterBottomSheet() {
    // Copy hiện tại để có thể huỷ thay đổi
    String tempStatus = _selectedStatus;
    Set<String> tempRoles = Set.from(_selectedRoles);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề
                  const Center(
                    child: Text(
                      'Lọc yêu cầu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Chọn role (multi-select)
                  const Text(
                    'Đối tượng:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Khách hàng'),
                          value: tempRoles.contains('customer'),
                          onChanged: (val) {
                            setStateBottomSheet(() {
                              if (val == true) {
                                tempRoles.add('customer');
                              } else {
                                tempRoles.remove('customer');
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Kỹ thuật viên'),
                          value: tempRoles.contains('technician'),
                          onChanged: (val) {
                            setStateBottomSheet(() {
                              if (val == true) {
                                tempRoles.add('technician');
                              } else {
                                tempRoles.remove('technician');
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chọn status (chỉ được chọn 1)
                  const Text(
                    'Trạng thái:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Đang xử lý'),
                          leading: Radio<String>(
                            value: 'pending',
                            groupValue: tempStatus,
                            onChanged: (val) {
                              setStateBottomSheet(() {
                                tempStatus = val!;
                              });
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Thành công'),
                          leading: Radio<String>(
                            value: 'completed',
                            groupValue: tempStatus,
                            onChanged: (val) {
                              setStateBottomSheet(() {
                                tempStatus = val!;
                              });
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Từ chối'),
                          leading: Radio<String>(
                            value: 'rejected',
                            groupValue: tempStatus,
                            onChanged: (val) {
                              setStateBottomSheet(() {
                                tempStatus = val!;
                              });
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nút Tìm kiếm
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Áp dụng filter
                        setState(() {
                          _selectedStatus = tempStatus;
                          _selectedRoles.clear();
                          _selectedRoles.addAll(tempRoles);
                        });
                        Navigator.pop(context);
                        _loadListRequestWithdraw(); // gọi lại API với query mới
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tìm kiếm',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper: hiển thị thông tin user dựa trên customerId / technicianId
  String _getUserDisplayName(dynamic withdraw) {
    if (withdraw['customerId'] != null) {
      final customer = withdraw['customerId'];
      return customer['phone'] ?? 'Khách hàng';
    } else if (withdraw['technicianId'] != null) {
      final tech = withdraw['technicianId'];
      return tech['fullName'] ?? 'Kỹ thuật viên';
    }
    return 'N/A';
  }

  String _getUserRoleText(dynamic withdraw) {
    if (withdraw['customerId'] != null) return 'Khách hàng';
    if (withdraw['technicianId'] != null) return 'Kỹ thuật viên';
    return '';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Thành công';
      case 'pending':
        return 'Đang xử lý';
      case 'rejected':
        return 'Từ chối';
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
      case 'rejected':
        return Colors.red;
      default:
        return Colors.black87;
    }
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
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Yêu cầu rút tiền',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            // Nút lọc
            InkWell(
              onTap: _showFilterBottomSheet,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.filter_list, size: 18, color: Color(0xFF1A1A1A)),
                    SizedBox(width: 4),
                    Text('Lọc', style: TextStyle(color: Color(0xFF1A1A1A))),
                  ],
                ),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadListRequestWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_withdrawals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _selectedStatus == 'pending'
                  ? 'Không có yêu cầu đang xử lý'
                  : _selectedStatus == 'completed'
                  ? 'Không có yêu cầu thành công'
                  : 'Không có yêu cầu thất bại',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _withdrawals.length,
      itemBuilder: (context, index) {
        final withdraw = _withdrawals[index];
        final bankInfo = withdraw['bankInfor'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              context.push(
                "${AdminRouterConfig.detailWithdraw}/${withdraw['_id']}",
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: mã + trạng thái
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Mã: ${withdraw['code']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(withdraw['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusText(withdraw['status']),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(withdraw['status']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Thông tin người dùng (hiển thị role + tên/phone)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            "${_getUserDisplayName(withdraw)} - ${_getUserRoleText(withdraw)}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 12),
                  //
                  // // Thông tin ngân hàng
                  // if (bankInfo != null) ...[
                  //   Container(
                  //     padding: const EdgeInsets.all(8),
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey[50],
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Row(
                  //           children: [
                  //             const Icon(Icons.account_balance, size: 16, color: Colors.grey),
                  //             const SizedBox(width: 8),
                  //             Expanded(
                  //               child: Text(
                  //                 bankInfo['bankName'] ?? 'N/A',
                  //                 style: const TextStyle(
                  //                   fontSize: 13,
                  //                   fontWeight: FontWeight.w500,
                  //                   color: Color(0xFF1A1A1A),
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //         const SizedBox(height: 4),
                  //         Padding(
                  //           padding: const EdgeInsets.only(left: 24),
                  //           child: Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text(
                  //                 'STK: ${bankInfo['accountNumber'] ?? 'N/A'}',
                  //                 style: const TextStyle(fontSize: 12, color: Colors.grey),
                  //               ),
                  //               Text(
                  //                 'Chủ TK: ${bankInfo['accountHolder'] ?? 'N/A'}',
                  //                 style: const TextStyle(fontSize: 12, color: Colors.grey),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  //   const SizedBox(height: 12),
                  // ],

                  // Thông tin số tiền
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Số tiền rút:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text(
                              FormatHelper.formatPrice(withdraw['amount'] ?? 0),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                            ),
                          ],
                        ),
                        // const SizedBox(height: 4),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     const Text('Phí:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        //     Text(
                        //       FormatHelper.formatPrice(withdraw['fee'] ?? 0),
                        //       style: const TextStyle(fontSize: 12, color: Colors.grey),
                        //     ),
                        //   ],
                        // ),
                        // const Divider(height: 12),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     const Text('Thực nhận:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                        //     Text(
                        //       FormatHelper.formatPrice(withdraw['netAmount'] ?? 0),
                        //       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Thời gian tạo
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        FormatHelper.formatDateTime(withdraw['createdAt']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),

                  // Lý do từ chối nếu có
                  if (withdraw['reasonRefusal'] != null && withdraw['reasonRefusal'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, size: 14, color: Colors.red[400]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lý do: ${withdraw['reasonRefusal']}',
                              style: TextStyle(fontSize: 12, color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}