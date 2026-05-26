import 'package:go_router/go_router.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/screens/customer/address/add.dart';
import 'package:spa_app/screens/customer/address/edit.dart';
import 'package:spa_app/screens/customer/address/list.dart';
import 'package:spa_app/screens/customer/order/canceled_screen.dart';
import 'package:spa_app/screens/customer/rate/create_rate_screen.dart';
import 'package:spa_app/screens/customer/rate/view_update_rate_screen.dart';
import 'package:spa_app/screens/customer/services/automatic_matching/create_automatic_matching_order.dart';
import 'package:spa_app/screens/customer/services/books/create_book_order.dart';
import 'package:spa_app/screens/customer/services/now/create_order_customer.dart';
import 'package:spa_app/screens/customer/deposit/choose_package.dart';
import 'package:spa_app/screens/customer/deposit/history.dart';
import 'package:spa_app/screens/customer/deposit/qr_code.dart';
import 'package:spa_app/screens/customer/discount/list_discount_screen.dart';
import 'package:spa_app/screens/customer/list_like_screen.dart';
import 'package:spa_app/screens/customer/list_like_technician.dart';
import 'package:spa_app/screens/customer/notification/customer_notification.dart';
import 'package:spa_app/screens/customer/services/automatic_matching/automatic_matching.dart';
import 'package:spa_app/screens/customer/services/books/book.dart';
import 'package:spa_app/screens/customer/profile/update_profile.dart';
import 'package:spa_app/screens/customer/services/now/order_now.dart';
import 'package:spa_app/screens/customer/to_technician/create_profile_technician.dart';
import 'package:spa_app/screens/customer/withdraw/confirm_request.dart';
import 'package:spa_app/screens/customer/withdraw/create_request.dart';
import 'package:spa_app/screens/customer/withdraw/history.dart';
import 'package:spa_app/screens/quanly/post/create_post_order.dart';
import 'package:spa_app/screens/quanly/post/technician_apply.dart';

import '../helper/check_login_helper.dart';
import '../screens/customer/detail_technician.dart';
import '../screens/customer/history_order.dart';
import '../screens/customer/home_customer_screen.dart';
import '../screens/customer/list_technician.dart';
import '../screens/customer/order/detail_order_screen.dart';

final List<GoRoute> managersRoutes = [
  GoRoute(
      path: '/home-managers',
      builder: (context, state) => const HomeCustomerScreen(),
      routes: [
        GoRoute(
          path: 'create-post-order',
          builder: (context, state) => const CreatePostOrderManager(),
        ),

        GoRoute(
          path: 'technician-apply',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return ListTechnicianApplyManager(data: data);
          },
        ),

        // GoRoute(
        //   path: 'detail-order/:id',
        //   builder: (context, state) {
        //     final id = state.pathParameters['id']!;
        //     return DetailsOrderScreen(id: id);
        //   },
        // ),
        //
        //
        // GoRoute(
        //   path: 'view-update-rate',
        //   builder: (context, state) {
        //     final data = state.extra as Map<String, dynamic>?;
        //
        //     return ViewOrUpdateRateScreen(
        //       data: data,
        //     );
        //   },
        // ),
        //
        //
        // GoRoute(
        //   path: 'history-order',
        //   builder: (context, state) => const HistoryOrderScreen(),
        // ),
      ]
  ),
];
