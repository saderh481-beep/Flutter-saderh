import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  String? _backupDirPath;
  int _totalFiles = 0;
  String? _storageSize;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/SADERH_Bitacoras');

      int fileCount = 0;
      int totalBytes = 0;

      if (await backupDir.exists()) {
        final entities = await backupDir.list().toList();
        for (final entity in entities) {
          if (entity is File) {
            fileCount++;
            totalBytes += await entity.length();
          }
        }
      }

      String sizeStr;
      if (totalBytes < 1024) {
        sizeStr = '$totalBytes B';
      } else if (totalBytes < 1024 * 1024) {
        sizeStr = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeStr = '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }

      if (!mounted) return;
      setState(() {
        _backupDirPath = backupDir.path;
        _totalFiles = fileCount;
        _storageSize = sizeStr;
      });
    } catch (_) {}
  }

  void _copyPath(String path) {
    Clipboard.setData(ClipboardData(text: path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ruta copiada al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.gray800,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/profile'),
        ),
        title: const Text('Configuracion', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Almacenamiento',
              children: [
                _buildStorageInfo(),
                const SizedBox(height: 14),
                _buildOpenFolderButton(),
              ],
            ),
            const SizedBox(height: 14),
            _buildSectionCard(
              title: 'Informacion de la app',
              children: [
                _buildInfoRow('Version', '1.0.0'),
                const Divider(height: 1, indent: 0),
                _buildInfoRow('Compilacion', '1'),
                const Divider(height: 1, indent: 0),
                _buildInfoRow('Universidad', 'UTMiR'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.gray800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStorageInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.dorado.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder, color: AppColors.dorado, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Carpeta privada',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(
                  _totalFiles > 0
                      ? '$_totalFiles archivos · $_storageSize'
                      : 'Sin archivos guardados',
                  style: const TextStyle(color: AppColors.gray400, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenFolderButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_backupDirPath != null) {
                  _copyPath(_backupDirPath!);
                }
              },
              icon: const Icon(Icons.copy_all, size: 18),
              label: const Text('Copiar ruta de la carpeta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.guinda,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          if (_backupDirPath != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _copyPath(_backupDirPath!),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.guinda.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.guinda.withValues(alpha: 0.08)),
                ),
                child: Text(
                  _backupDirPath!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.guinda,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.gray500, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray800)),
        ],
      ),
    );
  }
}
