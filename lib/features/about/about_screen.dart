import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          onPressed: () => context.go('/profile'),
        ),
        title: const Text('Acerca de', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.guinda, AppColors.guindaMid],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.school, size: 40, color: Colors.white),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  const Text(
                    'Universidad Tecnologica de\nMineral de la Reforma',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.guinda.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'UTMiR',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.guinda),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Desarrollado por:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.guinda),
                  ),
                  const SizedBox(height: 16),
                  _buildTeamMember('Jesus Aldair Quintana Samperio', Icons.person),
                  const SizedBox(height: 12),
                  _buildTeamMember('Erick Angel Tenorio Alcantara', Icons.person),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'SADERH Movil v1.0.0',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.guinda),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'App de gestion de campo para la Secretaria\nde Agricultura y Desarrollo Rural de Hidalgo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMember(String name, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.guinda.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.guinda, size: 18),
        ),
        const SizedBox(width: 12),
        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
