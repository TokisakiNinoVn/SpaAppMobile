// TODO Implement this library.
import 'package:go_router/go_router.dart';
import 'package:spa_app/screens/admin/account/technician/management_account_technician.dart';

import '../screens/admin/account/customer/management_account_customer.dart';
import '../screens/admin/banner/banner_management.dart';
import '../screens/admin/banner/create.dart';
import '../screens/admin/banner/edit.dart';
import '../screens/admin/discount/create.dart';
import '../screens/admin/discount/discount_management.dart';
import '../screens/admin/discount/edit.dart';
import '../screens/admin/home_admin_screen.dart';
import '../screens/admin/notification/notification_management.dart';
import '../screens/admin/service/add_service.dart';
import '../screens/admin/service/service_management.dart';
import '../screens/admin/service/update_service.dart';
import '../screens/admin/setting/setting_screen.dart';
import '../screens/admin/statistical/statistical_screen.dart';
import '../screens/admin/account/technician/edit_technician.dart';

final List<GoRoute> adminRoutes = [
  GoRoute(
    path: '/home-admin',
    builder: (context, state) => const HomeAdminScreen(),
    routes: [
      GoRoute(
        path: 'manage-account-technician',
        builder: (context, state) => const ManagementAccountTechnician(),
        routes: [
          GoRoute(
            path: 'edit-technician',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              return EditTechnicianScreen(data: data);
            },
          ),
        ]
      ),
      GoRoute(
        path: 'manage-account-customer',
        builder: (context, state) => const ManagementAccountCustomer(),
      ),
      GoRoute(
        path: 'manage-banner',
        builder: (context, state) => const BannerManagement(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateBannerScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              return EditBannerScreen(data: data);
            },
          ),
        ]
      ),

      GoRoute(
        path: 'manage-discount',
        builder: (context, state) => const DiscountManagement(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateDiscountScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              return EditDiscountScreen(data: data);
            },
          ),
        ]
      ),
      GoRoute(
        path: 'manage-service',
        builder: (context, state) => const ServiceManagement(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final item = state.extra as Map<String, dynamic>;
              return UpdateService(item: item);
            },
          ),
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddService(),
          ),
        ]
      ),
      GoRoute(
        path: 'settings-app',
        builder: (context, state) => const SettingScreen(),
      ),
      GoRoute(
        path: 'statistical',
        builder: (context, state) => const StatisticalScreen(),
      ),
      GoRoute(
        path: 'manage-notification',
        builder: (context, state) => const NotificationManagementScreen(),
      ),
    ],
  ),
];
