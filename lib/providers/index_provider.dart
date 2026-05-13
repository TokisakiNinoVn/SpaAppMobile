import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:spa_app/providers/user_provider.dart';


class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: child,
    );
  }
}
