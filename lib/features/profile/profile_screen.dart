import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/secure_storage.dart';
import '../../core/offline/hive_service.dart';
import '../../core/storage/local_data.dart';
import '../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _pendingSync = 0;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final count = await HiveService.pendingCount();
    if (mounted) setState(() => _pendingSync = count);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.gray800,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.guinda, AppColors.guindaMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.guinda.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    auth.nombre ?? 'Tecnico',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
                  ),
                  if (auth.rol != null)
                    Text(
                      auth.rol!,
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuCard([
              _MenuItem(icon: Icons.settings, title: 'Configuracion', subtitle: 'Almacenamiento', onTap: () => context.go('/config')),
            ]),
            const SizedBox(height: 12),
            _buildMenuCard([
              _MenuItem(icon: Icons.cloud_outlined, title: 'URL del servidor', onTap: () {
                SecureStorage.deleteToken();
                context.go('/connection');
              }),
              _MenuItem(icon: Icons.sync, title: 'Bitacoras pendientes', subtitle: '$_pendingSync pendientes'),
            ]),
            const SizedBox(height: 12),
            _buildMenuCard([
              _MenuItem(icon: Icons.gavel, title: 'Terminos y condiciones', onTap: () => context.go('/terminos')),
              _MenuItem(icon: Icons.info_outline, title: 'Acerca de', subtitle: 'UTMiR', onTap: () => context.go('/about')),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(),
                icon: const Icon(Icons.logout, color: AppColors.danger, size: 20),
                label: const Text('Cerrar sesion', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                leading: Icon(item.icon, color: AppColors.guinda, size: 22),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.gray800)),
                subtitle: item.subtitle != null ? Text(item.subtitle!, style: const TextStyle(color: AppColors.gray400, fontSize: 13)) : null,
                trailing: const Icon(Icons.chevron_right, color: AppColors.gray300, size: 20),
                onTap: item.onTap,
              ),
              if (i < items.length - 1) const Divider(height: 1, indent: 54, color: AppColors.gray100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesion'),
        content: const Text('Se borraran todos los datos locales. ¿Estas seguro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesion', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LocalData.clearAll();
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
}
