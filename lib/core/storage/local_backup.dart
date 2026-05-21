import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../offline/hive_service.dart';

class LocalBackup {
  static Future<String> getBackupPath() async {
    final baseDir = Platform.isAndroid
        ? Directory('${(await getExternalStorageDirectory())?.path ?? (await getApplicationDocumentsDirectory()).path}/SADERH/Bitacoras')
        : Directory('${(await getApplicationDocumentsDirectory()).path}/SADERH/Bitacoras');

    final now = DateTime.now();
    final monthDir = DateFormat('yyyy-MM').format(now);
    final fullPath = '${baseDir.path}/$monthDir';

    final dir = Directory(fullPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return fullPath;
  }

  static Future<File> saveFotoLocal({
    required XFile foto,
    required String actividadId,
    required String tipo,
  }) async {
    final backupPath = await getBackupPath();
    final actividadDir = Directory('$backupPath/$actividadId');
    if (!await actividadDir.exists()) {
      await actividadDir.create(recursive: true);
    }

    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final ext = foto.path.split('.').last;
    final fileName = '${tipo}_$timestamp.$ext';
    final destPath = '${actividadDir.path}/$fileName';

    final bytes = await foto.readAsBytes();
    final compressed = await _compressImage(bytes);
    final file = File(destPath);
    await file.writeAsBytes(compressed);

    return file;
  }

  static Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      final maxSize = 800;
      var w = image.width;
      var h = image.height;
      if (w > maxSize || h > maxSize) {
        if (w > h) {
          h = (h * maxSize / w).round();
          w = maxSize;
        } else {
          w = (w * maxSize / h).round();
          h = maxSize;
        }
      }

      final resized = img.copyResize(image, width: w, height: h);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      return bytes;
    }
  }

  static Future<void> cleanOldPhotos() async {
    final syncedItems = await HiveService.getSyncedItems();
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    for (final item in syncedItems) {
      final syncedAt = item['syncedAt'] as String?;
      if (syncedAt == null) continue;
      final date = DateTime.tryParse(syncedAt);
      if (date == null || date.isAfter(cutoff)) continue;

      final actividadId = item['actividadId'] as String?;
      if (actividadId == null) continue;

      final backupPath = await getBackupPath();
      final actividadDir = Directory('$backupPath/$actividadId');
      if (await actividadDir.exists()) {
        await actividadDir.delete(recursive: true);
      }

      await HiveService.removeItem(item['key'] as String);
    }
  }

  static Future<List<File>> getLocalPhotos(String actividadId) async {
    final backupPath = await getBackupPath();
    final actividadDir = Directory('$backupPath/$actividadId');
    if (!await actividadDir.exists()) return [];

    final files = await actividadDir.list().toList();
    return files.whereType<File>().toList();
  }
}
