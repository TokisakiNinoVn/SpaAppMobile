import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';

class GeneralManagementTab extends StatefulWidget {
  const GeneralManagementTab({super.key});

  @override
  State<GeneralManagementTab> createState() => _AccountAdminTabState();
}

class _AccountAdminTabState extends State<GeneralManagementTab> {
  bool _isGridView = false;

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.person_outline,
      'title': 'Quản lý tài khoản',
      'route': AdminRouterConfig.technicianManagementAccount,
      'color': Colors.blue,
    },
    // {
    //   'icon': Icons.group_outlined,
    //   'title': 'Quản lý khách',
    //   'route': AdminRouterConfig.customerManagementAccount,
    //   'color': Colors.purple,
    // },
    {
      'icon': Icons.menu_open,
      'title': 'Quản lý dịch vụ',
      'route': AdminRouterConfig.managementService,
      'color': Colors.pink,
    },
    {
      'icon': Icons.airplane_ticket_outlined,
      'title': 'Quản lý khuyến mãi',
      'route': AdminRouterConfig.managementDiscount,
      'color': Colors.redAccent,
    },
    {
      'icon': Icons.notifications_outlined,
      'title': 'Thông báo hệ thống',
      'route': AdminRouterConfig.notificationManagement,
      'color': Colors.red,
      'badge': '0',
    },
    {
      'icon': Icons.airplay_sharp,
      'title': 'Quản lý banner',
      'route': AdminRouterConfig.managementBanner,
      'color': Colors.greenAccent,
    },
    {
      'icon': Icons.bar_chart_outlined,
      'title': "Thống kê",
      'route': AdminRouterConfig.statistical,
      'color': Colors.green,
    },
    {
      'icon': Icons.wallet,
      'title': "Tài khoản thanh toán",
      'route': AdminRouterConfig.statistical,
      'color': Colors.orange,
    },
    // {
    //   'icon': Icons.report_gmailerrorred,
    //   'title': "Báo cáo",
    //   'route': AdminRouterConfig.managementBanner,
    //   'color': Colors.red,
    // },
    // {
    //   'icon': Icons.settings_outlined,
    //   'title': 'Cài đặt hệ thống',
    //   'route': AdminRouterConfig.settingApp,
    //   'color': Colors.orange,
    // },
  ];

  @override
  void initState() {
    super.initState();
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Chuyển đến màn hình tương ứng
          context.push(item['route']);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item['color'].withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'],
                      size: 32,
                      color: item['color'],
                    ),
                  ),
                  if (item.containsKey('badge'))
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          item['badge'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['title'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () {
          context.push(item['route']);
        },
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              decoration: BoxDecoration(
                color: item['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item['icon'],
                color: item['color'],
              ),
            ),
            if (item.containsKey('badge'))
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    item['badge'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          item['title'],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 20,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header với title và nút chuyển đổi
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quản lý chung',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _buildViewModeButton(
                          icon: Icons.grid_view,
                          isSelected: _isGridView,
                          onTap: _toggleViewMode,
                        ),
                        _buildViewModeButton(
                          icon: Icons.view_list,
                          isSelected: !_isGridView,
                          onTap: _toggleViewMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nội dung chính
            Expanded(
              child: _isGridView ? _buildGridView() : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cột
        childAspectRatio: 0.9, // Tỷ lệ chiều cao/rộng
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        return _buildGridItem(_menuItems[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        return _buildListItem(_menuItems[index]);
      },
    );
  }
}