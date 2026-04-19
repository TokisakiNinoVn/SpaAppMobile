import 'package:go_router/go_router.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/screens/customer/address/add.dart';
import 'package:spa_app/screens/customer/address/edit.dart';
import 'package:spa_app/screens/customer/address/list.dart';
import 'package:spa_app/screens/customer/create_order_customer.dart';
import 'package:spa_app/screens/customer/deposit/choose_package.dart';
import 'package:spa_app/screens/customer/deposit/history.dart';
import 'package:spa_app/screens/customer/deposit/qr_code.dart';
import 'package:spa_app/screens/customer/discount/list_discount_screen.dart';
import 'package:spa_app/screens/customer/list_like_screen.dart';
import 'package:spa_app/screens/customer/list_like_technician.dart';
import 'package:spa_app/screens/customer/notification/customer_notification.dart';
import 'package:spa_app/screens/customer/services/automatic_matching.dart';
import 'package:spa_app/screens/customer/services/book.dart';
import 'package:spa_app/screens/customer/profile/update_profile.dart';
import 'package:spa_app/screens/customer/withdraw/confirm_request.dart';
import 'package:spa_app/screens/customer/withdraw/create_request.dart';
import 'package:spa_app/screens/customer/withdraw/history.dart';

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
          path: 'order-now',
          builder: (context, state) => AddAddressScreen(),
        ),

        GoRoute(
          path: 'discounts',
          builder: (context, state) => ListDiscountScreen(),
        ),

        GoRoute(
            path: 'books',
            builder: (context, state) => BookScreen(),
        ),

        GoRoute(
            path: 'automatic-matching',
            builder: (context, state) => AutomaticMatchingScreen(),
        ),

        GoRoute(
          path: 'list-address',
          builder: (context, state) => const ListAddressScreen(),
          routes: [
            GoRoute(
              path: 'add-address',
              builder: (context, state) => AddAddressScreen(),
            ),
            GoRoute(
              path: '/edit-address',
              builder: (context, state) {
                final data = state.extra as Map<String, dynamic>;
                return EditAddressScreen(
                  address: data["address"],
                  id: data["id"],
                  isDefault: data["isDefault"],
                );
              },
            ),

          ]
        ),
        // GoRoute(
        //   path: 'detail-order/:id',
        //   builder: (context, state) {
        //     final id = state.pathParameters['id']!;
        //     return DetailsOrderScreen(id: id);
        //   },
        // ),
        GoRoute(
          path: 'likes',
          builder: (context, state) => const ListLikeScreen(),
        ),
        GoRoute(
          path: 'withdraw',
          builder: (context, state) => const CreateRequestWithdraw(),
          routes: [
            GoRoute(
              path: 'confirm',
              builder: (context, state) {
                final data = state.extra as Map<String, dynamic>;
                return ConfirmRequestWithdraw(data: data);
              },
            ),

            GoRoute(
              path: 'history',
              builder: (context, state) => HistoryWithdrawScreen(),
            ),
          ]
        ),
        GoRoute(
          path: 'choose-package',
          builder: (context, state) => const ChoosePackage(),
          routes: [
            GoRoute(
              path: 'history-deposit',
              builder: (context, state) => HistoryDepositScreen(),
            ),
            GoRoute(
              path: 'qr-deposit/:amount',
              builder: (context, state) {
                final amountStr = state.pathParameters['amount'];
                final amount = int.tryParse(amountStr ?? '0') ?? 0;

                return QRCodeScreen(amount: amount);
              },
            ),

          ]
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
