import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import '../../../../helper/snackbar_helper.dart';
import '../../../../services/statistical_service.dart'; // giả sử service đã được tạo

class StatisticalScreen extends StatefulWidget {
  const StatisticalScreen({super.key});

  @override
  _StatisticalScreenState createState() => _StatisticalScreenState();
}

class _StatisticalScreenState extends State<StatisticalScreen> {
  final StatisticalService _statisticalService = StatisticalService();

  DateTimeRange? _selectedDateRange;
  String _groupBy = 'day'; // day, week, month
  String _status = 'all'; // all, pending, approved, working, expired, rejected, canceled, done

  bool _isLoading = false;
  Map<String, dynamic>? _statData;

  // Danh sách các trạng thái cho dropdown
  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'pending', 'label': 'Chờ duyệt'},
    {'value': 'approved', 'label': 'Đã duyệt'},
    {'value': 'working', 'label': 'Đang thực hiện'},
    {'value': 'done', 'label': 'Hoàn thành'},
    {'value': 'expired', 'label': 'Hết hạn'},
    {'value': 'rejected', 'label': 'Từ chối'},
    {'value': 'canceled', 'label': 'Đã hủy'},
  ];

  final List<Map<String, String>> _groupByOptions = [
    {'value': 'day', 'label': 'Theo ngày'},
    {'value': 'week', 'label': 'Theo tuần'},
    {'value': 'month', 'label': 'Theo tháng'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      // Xây dựng query string
      final params = <String, String>{};
      if (_selectedDateRange != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        params['endDate'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }
      if (_groupBy != 'day') params['groupBy'] = _groupBy;
      if (_status != 'all') params['status'] = _status;

      final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final response = await _statisticalService.getStatisticalData(queryString);

      if (response['success'] == true) {
        setState(() {
          _statData = response['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      SnackBarHelper.showError(context, 'Không thể tải dữ liệu: $e');
    }
  }

  void _applyFilters() {
    _fetchData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Thống kê hệ thống', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bộ lọc
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ]),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedDateRange == null
                                ? 'Chọn khoảng thời gian'
                                : '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                            style: TextStyle(color: _selectedDateRange == null ? Colors.grey : Colors.black),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dropdown Group By
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _groupBy,
                        underline: const SizedBox(),
                        items: _groupByOptions.map((opt) {
                          return DropdownMenuItem(value: opt['value'], child: Text(opt['label']!));
                        }).toList(),
                        onChanged: (val) => setState(() => _groupBy = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _status,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _statusOptions.map((opt) {
                            return DropdownMenuItem(value: opt['value'], child: Text(opt['label']!));
                          }).toList(),
                          onChanged: (val) => setState(() => _status = val!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.search, color: Colors.white,),
                      label: const Text('Lọc', style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(backgroundColor: ColorConfig.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _statData == null
                ? const Center(child: Text('Không có dữ liệu'))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(_statData!['summary']),
                  const SizedBox(height: 24),
                  // _buildStatusBreakdown(_statData!['statusBreakdown']),
                  // const SizedBox(height: 24),
                  _buildTypeOrderBreakdown(_statData!['typeOrderBreakdown']),
                  const SizedBox(height: 24),
                  _buildTimelineChart(_statData!['timeline']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    final totalOrders = summary['totalOrders'] ?? 0;
    final totalRevenue = (summary['totalRevenue'] ?? 0).toDouble();
    final totalDeposit = (summary['totalDeposit'] ?? 0).toDouble();
    final avgOrder = (summary['averageOrderValue'] ?? 0).toDouble();

    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildCard('Tổng đơn', totalOrders.toString(), Icons.receipt_long),
        _buildCard('Doanh thu', formatCurrency.format(totalRevenue), Icons.attach_money),
        _buildCard('Tổng cọc', formatCurrency.format(totalDeposit), Icons.account_balance_wallet),
        _buildCard('Trung bình/đơn', formatCurrency.format(avgOrder), Icons.trending_up),
      ],
    );
  }

  Widget _buildCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.green.shade700),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown(List<dynamic> breakdown) {
    if (breakdown.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phân bố theo trạng thái', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _buildPieChart(breakdown),
        ),
        const SizedBox(height: 12),
        ...breakdown.map((e) => _buildLegendRow(e['_id'], e['count'])),
      ],
    );
  }

  Widget _buildTypeOrderBreakdown(List<dynamic> breakdown) {
    if (breakdown.isEmpty) return const SizedBox();
    final Map<String, String> typeNames = {
      'book': 'Đặt lịch',
      'automatic-matching': 'Ghép tự động',
      'order-now': 'Đặt ngay',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phân bố theo loại đơn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _buildPieChart(breakdown, labelMapper: (id) => typeNames[id] ?? id),
        ),
        const SizedBox(height: 12),
        ...breakdown.map((e) => _buildLegendRow(typeNames[e['_id']] ?? e['_id'], e['count'])),
      ],
    );
  }

  Widget _buildPieChart(List<dynamic> data, {String Function(String)? labelMapper}) {
    final total = data.fold<int>(0, (sum, item) => sum + (item['count'] as int));
    return PieChart(
      PieChartData(
        sections: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final value = (item['count'] as num).toDouble();
          final percent = value / total;
          return PieChartSectionData(
            color: _getColor(index),
            value: value,
            title: '${(percent * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildLegendRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: _getColor(_legendIndex++)),
          const SizedBox(width: 8),
          Text('$label: $count'),
        ],
      ),
    );
  }

  int _legendIndex = 0;
  Color _getColor(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  Widget _buildTimelineChart(List<dynamic> timeline) {
    if (timeline.isEmpty) return const SizedBox();
    final titles = timeline.map<String>((e) => e['period'].toString()).toList();
    final orders = timeline.map<int>((e) => e['orders'] as int).toList();
    final revenue = timeline.map<double>((e) => (e['revenue'] as num).toDouble()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Xu hướng theo thời gian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (orders.isEmpty ? 0 : orders.reduce((a, b) => a > b ? a : b)).toDouble() + 2,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < titles.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(timeline.length, (i) {
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: orders[i].toDouble(), color: Colors.blue, width: 20),
                ]);
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Doanh thu (VNĐ)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < titles.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) {
                    return Text(NumberFormat.compactCurrency(locale: 'vi_VN', symbol: '').format(value));
                  }),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(revenue.length, (i) => FlSpot(i.toDouble(), revenue[i])),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}