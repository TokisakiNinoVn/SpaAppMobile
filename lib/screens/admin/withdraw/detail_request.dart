import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/withdraw_service.dart';
import '../../../helper/format_helper.dart';

class ListRequestWithdraw extends StatefulWidget {
  @override
  State<ListRequestWithdraw> createState() => _ListRequestWithdrawState();
}

class _ListRequestWithdrawState extends State<ListRequestWithdraw>
    with SingleTickerProviderStateMixin {
  final WithdrawService _withdrawService = WithdrawService();

  List<dynamic> _allRequestWithdraw = [];
  List<dynamic> _filteredRequestWithdraw = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedStatus = 'pending'; // Mặc định là pending

  late TabController _tabController;

  final List<String> _statusTabs = ['pending', 'success', 'failed'];
  final Map<String, String> _statusLabels = {
    'pending': 'Đang xử lý',
    'success': 'Thành công',
    'failed': 'Thất bại',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedStatus = _statusTabs[_tabController.index];
          _filterRequestsByStatus();
        });
      }
    });
    _loadListRequestWithdraw();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadListRequestWithdraw() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _withdrawService.listRequestWithdraw();

      if (response['status'] == 'success') {
        setState(() {
          _allRequestWithdraw = response['data']['withdraws'] ?? [];
          _filterRequestsByStatus();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ??
            'Không thể tải danh sách yêu cầu rút tiền');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading list withdraw request : $e');
    }
  }

  void _filterRequestsByStatus() {
    setState(() {
      _filteredRequestWithdraw = _allRequestWithdraw
          .where((withdraw) => withdraw['status'] == _selectedStatus)
          .toList();
    });
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
            const Text(
              'Yêu cầu rút tiền',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF1A1A1A),
              labelColor: const Color(0xFF1A1A1A),
              unselectedLabelColor: Colors.grey,
              tabs: _statusTabs.map((status) {
                int count = _allRequestWithdraw
                    .where((w) => w['status'] == status)
                    .length;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_statusLabels[status]!),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedStatus == status
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedStatus == status
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
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

    if (_filteredRequestWithdraw.isEmpty) {
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
              _selectedStatus == 'pending'
                  ? 'Không có yêu cầu đang xử lý'
                  : _selectedStatus == 'success'
                  ? 'Không có yêu cầu thành công'
                  : 'Không có yêu cầu thất bại',
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
      itemCount: _filteredRequestWithdraw.length,
      itemBuilder: (context, index) {
        final withdraw = _filteredRequestWithdraw[index];
        final userInfo = withdraw['userId'];
        final bankInfo = withdraw['bankInfor'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            // onTap: () {
            //   context.push(
            //     AdminRouterConfig.listWithdraw,
            //     extra: withdraw,
            //   );
            // },
            onTap: () {
              context.push(
                "${AdminRouterConfig.listWithdraw}/${withdraw['_id']}",
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header với mã và trạng thái
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(withdraw['status'])
                              .withOpacity(0.1),
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

                  // Thông tin người dùng
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userInfo?['phone'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Thông tin ngân hàng
                  if (bankInfo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.account_balance,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bankInfo['bankName'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STK: ${bankInfo['accountNumber'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Chủ TK: ${bankInfo['accountHolder'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

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
                            const Text(
                              'Số tiền rút:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              FormatHelper.formatPrice(withdraw['amount'] ?? 0),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Phí:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              FormatHelper.formatPrice(withdraw['fee'] ?? 0),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Thực nhận:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              FormatHelper.formatPrice(withdraw['netAmount'] ?? 0),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Thời gian tạo
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        FormatHelper.formatDateTime(withdraw['createdAt']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Hiển thị lý do từ chối nếu có
                  if (withdraw['reasonRefusal'] != null &&
                      withdraw['reasonRefusal'].isNotEmpty) ...[
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
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lý do: ${withdraw['reasonRefusal']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
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