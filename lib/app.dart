import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'router.dart';

final goRouter = createRouter();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SADERH Móvil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: goRouter,
    );
  }
}
