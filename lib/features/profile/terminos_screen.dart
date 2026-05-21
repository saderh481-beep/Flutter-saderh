import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

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
        title: const Text('Terminos y condiciones', style: TextStyle(fontWeight: FontWeight.w600)),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terminos y condiciones',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Politicas de uso de SADERH Movil',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            _buildCard(
              icon: Icons.shield,
              title: '1. Aceptacion de terminos',
              content: 'Al usar SADERH Movil, aceptas los siguientes terminos. La app es una herramienta '
                  'oficial de la Secretaria de Agricultura y Desarrollo Rural de Hidalgo para la '
                  'gestion de campo y registro de bitacoras tecnicas.',
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.lock,
              title: '2. Privacidad de datos',
              content: 'Los datos recopilados son de caracter oficial y estan protegidos conforme a la '
                  'Ley de Proteccion de Datos Personales. La informacion de beneficiarios, '
                  'geolocalizacion y evidencia fotografica se almacena de forma segura.',
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.verified_user,
              title: '3. Uso responsable',
              content: 'El tecnico es responsable de la veracidad de la informacion registrada. '
                  'Las bitacoras y evidencias fotograficas tienen valor oficial.',
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.security,
              title: '4. Almacenamiento seguro',
              content: 'Los datos se cifran tanto en transito (HTTPS) como en reposo '
                  '(cifrado AES-256 en dispositivo).',
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.guinda.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
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
                    color: AppColors.guinda,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
