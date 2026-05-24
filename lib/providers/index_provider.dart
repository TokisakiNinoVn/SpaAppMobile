import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:spa_app/providers/information_provider.dart';
import 'package:spa_app/providers/order_provider.dart';
import 'package:spa_app/providers/selected_tab_provider.dart';
import 'package:spa_app/providers/service_provider.dart';
import 'package:spa_app/providers/user_provider.dart';
import 'package:spa_app/providers/withdraw_provider.dart';


class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => InformationProvider()),
        ChangeNotifierProvider(create: (_) => SelectedTabProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => WithdrawProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: child,
    );
  }
}
