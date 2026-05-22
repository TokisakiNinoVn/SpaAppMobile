import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/helper/logger_utils.dart';

import 'package:spa_app/screens/technician/add_technician_screen.dart';
import 'package:spa_app/screens/technician/notification/technician_list_notification.dart';
import 'package:spa_app/screens/technician/order/detail_order_screen.dart';
import 'package:spa_app/screens/technician/order/details_new_order.dart';
import 'package:spa_app/screens/technician/order/technician_canceled_order.dart';
import 'package:spa_app/screens/technician/service/technicianupdate_service.dart';
import 'package:spa_app/screens/technician/technician/update_profile_technician.dart';
import '../screens/technician/home_technician_screen.dart';
import '../screens/technician/order/history_order.dart';
import '../screens/technician/statistical/statistical_screen.dart';

final List<GoRoute> technicianRoutes = [
  GoRoute(
      path: '/home-technician',
      builder: (context, state) {
        final initialIndex = state.extra as int? ?? 0;
        // appLog("initialIndex: $initialIndex");
        return HomeTechnicianScreen(
          initialIndex: initialIndex,
        );
      },
      // builder: (context, state) => const HomeTechnicianScreen(),
      // pageBuilder: (context, state) {
      //   final initialIndex = state.extra as int? ?? 0;
      //     appLog("${state.extra} initialIndex: $initialIndex");
      //
      //   return MaterialPage(
      //     key: ValueKey(initialIndex),
      //     child: HomeTechnicianScreen(
      //       initialIndex: initialIndex,
      //     ),
      //   );
      // },
      // pageBuilder: (context, state) {
      //   final initialIndex = state.extra as int? ?? 0;
      //   return MaterialPage(
      //     key: UniqueKey(),  // luôn tạo mới
      //     child: HomeTechnicianScreen(initialIndex: initialIndex),
      //   );
      // },
      routes: [
        GoRoute(
          path: 'technician-update-service',
          builder: (context, state) => const TechnicianUpdateService(),
        ),
        GoRoute(
          path: 'canceled-order/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;

            return TechnicianCanceledOrder(
              idOrder: id,
            );
          }
        ),
        GoRoute(
          path: 'history-order',
          builder: (context, state) => const HistoryOrder(),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => ListNotificationTechnician(),
        ),
        GoRoute(
          path: 'statistical',
          builder: (context, state) => const StatisticalScreen(),
        ),
        GoRoute(
          path: 'add-technician',
          builder: (context, state) => const AddTechnicianScreen(),
        ),

        GoRoute(
          path: 'orders/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return DetailsNewOrderScreen(orderId: orderId);
          },
        ),

        GoRoute(
          path: 'details-orders/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;

            return DetailsOrderTechnician(
              id: id,
              isNewOrder: state.extra as bool? ?? false,
            );
          },
        ),

        GoRoute(
          path: '/update-profile',
          builder: (context, state) => const UserEditTechnicianScreen(),
        ),

      ]
  ),
];
