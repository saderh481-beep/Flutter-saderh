import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notificationsEnabled = true;
  bool _isGranting = false;

  final _permissions = [
    _PermissionData(
      icon: Icons.location_on,
      title: 'Ubicacion',
      description:
          'Registramos tu ubicacion al guardar una bitacora para verificar la visita.',
      permission: Permission.locationWhenInUse,
      isCritical: true,
    ),
    _PermissionData(
      icon: Icons.camera_alt,
      title: 'Camara',
      description:
          'Tomaras fotos de evidencia durante las visitas tecnicas.',
      permission: Permission.camera,
      isCritical: true,
    ),
    _PermissionData(
      icon: Icons.wifi,
      title: 'Estado de red',
      description:
          'Detectamos si tienes conexion para sincronizar en tiempo real.',
      permission: Permission.notification,
      isCritical: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _grantPermissions() async {
    setState(() => _isGranting = true);

    for (final p in _permissions) {
      if (!p.isCritical) continue;
      final status = await p.permission.request();
      if (status.isDenied && p.isCritical) {
        if (!mounted) return;
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Permiso requerido'),
            content: Text(
              'El permiso de ${p.title} es necesario para el funcionamiento de la app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ir a Configuracion'),
              ),
            ],
          ),
        );
        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
        setState(() => _isGranting = false);
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permisos_concedidos', true);
    await prefs.setBool('notificaciones_activas', _notificationsEnabled);

    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.guinda,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/onboarding'),
        ),
        title: Row(
          children: [
            Image.asset('assets/Mesa-de-trabajo-2_1.png', width: 24, height: 24, fit: BoxFit.contain),
            const SizedBox(width: 8),
            const Text('SADERH', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.guinda, AppColors.guindaMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permisos necesarios',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Para usar SADERH necesitamos algunos permisos',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            ..._permissions.map((p) => _buildPermissionCard(p)),
            const SizedBox(height: 12),
            _buildSwitchCard(
              icon: Icons.notifications_outlined,
              title: 'Notificaciones',
              description:
                  'Te avisamos cuando una sincronizacion se complete.',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isGranting ? null : _grantPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.guinda,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isGranting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Conceder permisos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(_PermissionData p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.guinda, AppColors.guindaMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(p.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * _permissions.indexOf(p)).ms, duration: 300.ms);
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.dorado.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.guinda, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.guinda.withValues(alpha: 0.4),
            activeColor: AppColors.guinda,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _PermissionData {
  final IconData icon;
  final String title;
  final String description;
  final Permission permission;
  final bool isCritical;

  const _PermissionData({
    required this.icon,
    required this.title,
    required this.description,
    required this.permission,
    required this.isCritical,
  });
}
