import '../api/api_service.dart';
import 'hive_service.dart';

class SyncService {
  final ApiService _apiService;

  SyncService(this._apiService);

  Future<SyncResult> syncAll() async {
    final pending = await HiveService.getPendingItems();
    if (pending.isEmpty) return SyncResult(synced: 0, errors: []);

    final operaciones = <Map<String, dynamic>>[];
    for (final item in pending) {
      final payload = item['payload'] as Map<String, dynamic>? ?? item;
      operaciones.add({
        'timestamp': item['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
        'operacion': item['operacion'] ?? 'crear_bitacora',
        'payload': payload,
      });
    }

    operaciones.sort((a, b) {
      final ta = a['timestamp'] as String;
      final tb = b['timestamp'] as String;
      return ta.compareTo(tb);
    });

    int synced = 0;
    final errors = <String>[];

    try {
      final result = await _apiService.syncOperaciones(operaciones);
      final resultados = result['resultados'] as List<dynamic>? ?? [];

      for (int i = 0; i < resultados.length; i++) {
        final r = resultados[i] as Map<String, dynamic>;
        final syncId = r['sync_id'] as String?;
        final exito = r['exito'] == true || r['duplicado'] == true;

        String? matchedKey;
        if (syncId != null) {
          for (final p in pending) {
            final payload = p['payload'] as Map<String, dynamic>?;
            if (payload != null && payload['sync_id'] == syncId) {
              matchedKey = p['key'] as String?;
              break;
            }
          }
        }
        matchedKey ??= (i < pending.length) ? pending[i]['key'] as String? : null;

        if (matchedKey != null) {
          if (exito) {
            await HiveService.markSynced(matchedKey);
            await HiveService.removeItem(matchedKey);
            synced++;
          } else {
            errors.add('${r['sync_id']}: ${r['error'] ?? 'Error desconocido'}');
          }
        }
      }
    } catch (e) {
      return SyncResult(synced: 0, errors: ['$e']);
    }

    return SyncResult(synced: synced, errors: errors);
  }

  Future<Map<String, dynamic>?> downloadDelta(String? ultimoSync) async {
    try {
      return await _apiService.syncDelta(ultimoSync);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fullSync() async {
    return downloadDelta(null);
  }
}

class SyncResult {
  final int synced;
  final List<String> errors;

  SyncResult({required this.synced, required this.errors});
}
