import 'package:workmanager/workmanager.dart';

import '../api/api_service.dart';
import '../auth/auth_provider.dart';
import '../auth/secure_storage.dart';
import 'hive_service.dart';
import 'sync_service.dart';

const bgSyncTask = 'syncBitacoras';

@pragma('vm:entry-point')
void bgSyncCallback() {
  Workmanager().executeTask((task, input) async {
    if (task != bgSyncTask) return false;

    try {
      final hasToken = await SecureStorage.hasToken();
      if (!hasToken) return false;

      final auth = AuthProvider();
      final api = ApiService(auth);
      final sync = SyncService(api);

      final pending = await HiveService.getPendingItems();
      if (pending.isEmpty) return true;

      await sync.syncAll();
      return true;
    } catch (_) {
      return false;
    }
  });
}

class BackgroundSync {
  static Future<void> init() async {
    await Workmanager().initialize(bgSyncCallback);
    await Workmanager().registerPeriodicTask(
      'syncBitacorasPeriodic',
      bgSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> syncNow() async {
    await Workmanager().registerOneOffTask(
      'syncBitacorasNow',
      bgSyncTask,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
