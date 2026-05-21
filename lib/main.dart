import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/offline/hive_service.dart';
import 'core/offline/background_sync.dart';
import 'core/notifications/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await HiveService.init();
  await BackgroundSync.init();
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
