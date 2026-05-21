import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _slides = [
    _SlideData(
      icon: Icons.agriculture,
      title: 'Bienvenido a SADERH',
      description:
          'La herramienta oficial de gestion de campo para la Secretaria de Agricultura y Desarrollo Rural de Hidalgo.',
    ),
    _SlideData(
      icon: Icons.assignment,
      title: 'Gestiona tus actividades',
      description:
          'Consulta y administra todas tus actividades del dia desde un solo lugar.',
    ),
    _SlideData(
      icon: Icons.camera_alt,
      title: 'Registra bitacoras',
      description:
          'Captura evidencia fotografica, agrega observaciones y registra la geolocalizacion de cada visita.',
    ),
    _SlideData(
      icon: Icons.wifi_off,
      title: 'Funciona sin internet',
      description:
          'Trabaja sin conexion. Tus datos se sincronizaran automaticamente.',
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completado', true);
    if (!mounted) return;
    context.go('/permissions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Image.asset('assets/Mesa-de-trabajo-2_1.png', width: 32, height: 32, fit: BoxFit.contain),
                  const SizedBox(width: 8),
                  Text('SADERH', style: TextStyle(color: AppColors.guinda, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      _currentPage < _slides.length - 1 ? 'Omitir' : '',
                      style: const TextStyle(color: AppColors.guinda, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (_, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.guinda, AppColors.guindaMid],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.guinda.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(slide.icon, size: 44, color: Colors.white),
                        ).animate().fadeIn(duration: 400.ms).scale(delay: (100 * index).ms),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.guinda,
                          ),
                        ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppColors.guinda : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _skipOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.guinda,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage < _slides.length - 1 ? 'Siguiente' : 'Comenzar',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String description;
  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
