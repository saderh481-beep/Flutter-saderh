import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static const _boxName = 'offline_queue';
  static Box<String>? _box;
  static String? _deviceId;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    _deviceId = '${Platform.localHostname}_${Platform.operatingSystemVersion}';
    final key = _deriveKey();
    _box = await Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );
  }

  static List<int> _deriveKey() {
    final seed = 'saderh_offline_key_2024_hidalgo${_deviceId ?? ''}';
    final bytes = utf8.encode(seed);
    final hash = sha256.convert(bytes);
    return hash.bytes;
  }

  static Future<void> enqueue(Map<String, dynamic> item) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final json = jsonEncode(item);
    await _box?.put(id, json);
  }

  static Future<List<Map<String, dynamic>>> getPendingItems() async {
    if (_box == null) return [];
    final items = <Map<String, dynamic>>[];
    for (final key in _box!.keys) {
      final json = _box!.get(key);
      if (json != null) {
        items.add({
          'key': key,
          ...jsonDecode(json) as Map<String, dynamic>,
        });
      }
    }
    return items;
  }

  static Future<void> removeItem(String key) async {
    await _box?.delete(key);
  }

  static Future<int> pendingCount() async {
    return _box?.length ?? 0;
  }

  static Future<void> clearAll() async {
    await _box?.clear();
  }

  static Future<void> markSynced(String key) async {
    final item = _box?.get(key);
    if (item != null) {
      final data = jsonDecode(item) as Map<String, dynamic>;
      data['synced'] = true;
      data['syncedAt'] = DateTime.now().toIso8601String();
      await _box?.put(key, jsonEncode(data));
    }
  }

  static Future<List<Map<String, dynamic>>> getSyncedItems() async {
    if (_box == null) return [];
    final items = <Map<String, dynamic>>[];
    for (final key in _box!.keys) {
      final json = _box!.get(key);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        if (data['synced'] == true) {
          items.add({'key': key, ...data});
        }
      }
    }
    return items;
  }
}
