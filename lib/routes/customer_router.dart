import 'package:go_router/go_router.dart';
import 'package:spa_app/screens/customer/create_order_customer.dart';
import 'package:spa_app/screens/customer/list_like_screen.dart';
import 'package:spa_app/screens/customer/list_like_technician.dart';
import 'package:spa_app/screens/customer/notification/customer_notification.dart';
import 'package:spa_app/screens/customer/update_profile.dart';

import '../helper/check_login_helper.dart';
import '../screens/customer/detail_technician.dart';
import '../screens/customer/history_order.dart';
import '../screens/customer/home_customer_screen.dart';
import '../screens/customer/list_technician.dart';
import '../screens/customer/order/detail_order_screen.dart';

final List<GoRoute> customerRoutes = [
  GoRoute(
      path: '/home-customer',
      builder: (context, state) => const HomeCustomerScreen(),
      routes: [
        GoRoute(
          path: 'detail-order/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DetailsOrderScreen(id: id);
          },
        ),
        GoRoute(
          path: 'likes',
          builder: (context, state) => const ListLikeScreen(),
        ),
        GoRoute(
            path: 'list-technician',
            builder: (context, state) => const ListTechnicianScreen(),
            routes: [
              GoRoute(
                path: 'list-like-technician',
                builder: (context, state) => const ListLikeTechnicianScreen(),
              ),
              GoRoute(
                  path: 'detail-technician/:id',
                  redirect: (context, state) async {
                    final loggedIn = await CheckLoginHelper.isLoggedIn();
                    if (!loggedIn) return '/login-otp';
                    return null;
                  },
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return DetailsTechnicianScreen(id: id);
                  },
                  routes: [
                    GoRoute(
                      path: 'create-order-technician',
                      // builder: (context, state) => const CreateOrderTechnicianScreen(),
                      // path: 'service/edit',
                      builder: (context, state) {
                        final data = state.extra as Map<String, dynamic>;
                        return CreateOrderTechnicianScreen(data: data);
                      },
                    ),
                  ]
              ),
              GoRoute(
                path: 'create-order-technician',
                // builder: (context, state) => const CreateOrderTechnicianScreen(),
                // path: 'service/edit',
                builder: (context, state) {
                  final data = state.extra as Map<String, dynamic>;
                  return CreateOrderTechnicianScreen(data: data);
                },
              ),
            ]
        ),
        GoRoute(
          path: 'history-order',
          builder: (context, state) => const HistoryOrderScreen(),
        ),
        GoRoute(
          path: 'update-profile',
          builder: (context, state) => const UpdateProfileScreen(),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => ListNotificationScreen(),
        ),
        GoRoute(
          path: 'likes-technician',
          builder: (context, state) => const ListLikeTechnicianScreen(),
        ),
      ]
  ),
];
