import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class BitacoraSuccessScreen extends StatelessWidget {
  final bool isOffline;

  const BitacoraSuccessScreen({super.key, this.isOffline = false});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isOffline ? Icons.cloud_done : Icons.check,
                    color: Colors.white,
                    size: 64,
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 32),
                Text(
                  isOffline ? 'Guardado localmente' : 'Bitácora registrada',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.guinda,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: 12),
                Text(
                  isOffline
                      ? 'Se sincronizará automáticamente cuando tengas conexión a internet'
                      : 'La visita técnica se registró y subió correctamente al servidor',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOffline ? Colors.orange[50] : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOffline ? Colors.orange[200]! : AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOffline ? Icons.cloud_off : Icons.cloud_done,
                        size: 18,
                        color: isOffline ? Colors.orange[700] : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOffline ? 'Pendiente de sincronización' : 'Sincronizado',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOffline ? Colors.orange[700] : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.home, size: 20),
                    label: const Text(
                      'Volver al inicio',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.guinda,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: AppColors.guinda.withValues(alpha: 0.4),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 400.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
