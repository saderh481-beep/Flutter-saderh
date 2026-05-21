import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_service.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/storage/local_data.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/beneficiario.dart';
import '../../shared/models/actividad.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _code = <int>[];
  bool _isLoading = false;
  bool _hayError = false;
  String? _errorMessage;

  void _addDigit(int digit) {
    if (_code.length >= 5 || _isLoading) return;
    setState(() {
      _code.add(digit);
      _hayError = false;
      _errorMessage = null;
    });
    if (_code.length == 5) {
      _login();
    }
  }

  void _removeDigit() {
    if (_code.isEmpty) return;
    setState(() {
      _code.removeLast();
      _hayError = false;
      _errorMessage = null;
    });
  }

  Future<void> _login() async {
    final codigo = _code.join();
    setState(() {
      _isLoading = true;
      _hayError = false;
      _errorMessage = null;
    });

    try {
      final api = ApiService(ref.read(authProvider.notifier));
      final response = await api.login(codigo);

      final token = response['token'] as String;
      final tecnico = response['tecnico'] as Map<String, dynamic>;

      await ref.read(authProvider.notifier).login(
            token: token,
            id: tecnico['id']?.toString() ?? '',
            nombre: tecnico['nombre'] as String? ?? '',
            rol: tecnico['rol'] as String? ?? '',
            codigo: codigo,
          );

      if (!mounted) return;

      await _fetchInitialData(api, ref);

      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      String errorMsg = 'Error de conexion';
      final errStr = e.toString();
      if (errStr.contains('Código') || errStr.contains('codigo')) {
        errorMsg = 'Codigo incorrecto';
      } else if (errStr.contains('inactivo')) {
        errorMsg = 'Usuario inactivo';
      } else if (errStr.contains('vencido') || errStr.contains('Periodo')) {
        errorMsg = 'Periodo vencido';
      } else if (errStr.contains('conexion') || errStr.contains('internet')) {
        errorMsg = 'Sin conexion a internet';
      } else {
        errorMsg = errStr;
      }
      setState(() {
        _isLoading = false;
        _hayError = true;
        _errorMessage = errorMsg;
        _code.clear();
      });
    }
  }

  Future<void> _fetchInitialData(ApiService api, WidgetRef ref) async {
    List<Beneficiario> beneficiarios = [];
    List<Actividad> actividades = [];

    try {
      final result = await api.getAsignaciones();
      final asignaciones = result['asignaciones'] as List<dynamic>? ?? [];

      for (final a in asignaciones) {
        final item = a as Map<String, dynamic>;
        final tipo = item['tipo_asignacion'] as String?;

        if (tipo == 'beneficiario') {
          final benData = item['beneficiario'] as Map<String, dynamic>?;
          if (benData != null) {
            beneficiarios.add(Beneficiario.fromJson(benData));
          }
        } else if (tipo == 'actividad') {
          actividades.add(Actividad.fromJson(item));
        }
      }
    } catch (_) {}

    if (beneficiarios.isNotEmpty || actividades.isNotEmpty) {
      await LocalData.saveFromApi(
        beneficiarios: beneficiarios,
        actividades: actividades.map((e) => e.toJson()).toList(),
      );
    } else {
      await LocalData.seedIfEmpty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 88,
                height: 88,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/Mesa-de-trabajo-2_1.png',
                    width: 88,
                    height: 88,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                'SADERH',
                style: TextStyle(
                  color: AppColors.guinda,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),
              Text(
                'Gestion de Campo',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const Spacer(flex: 1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                    const Text(
                      'Ingresa tu codigo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.guinda,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Codigo de tecnico de 5 digitos',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _code.length ? AppColors.guinda : Colors.grey[200],
                            border: Border.all(
                              color: i < _code.length ? AppColors.guinda : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ).animate(
                      target: _hayError ? 1.0 : 0.0,
                      onComplete: (_) => setState(() => _hayError = false),
                    ).shake(duration: 500.ms, hz: 3),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ).animate().fadeIn().shake(),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Column(
                        children: [
                          CircularProgressIndicator(color: AppColors.guinda, strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text('Ingresando...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ).animate().fadeIn()
                    else
                      _buildNumpad(),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (col) => _numpadButton(row * 3 + col + 1),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 72),
              _numpadButton(0),
              _numpadButton(-1, icon: Icons.backspace_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numpadButton(int digit, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 72,
      height: 64,
      child: Material(
        color: const Color(0xFFF0F0F2),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (digit == -1) {
              _removeDigit();
            } else {
              _addDigit(digit);
            }
          },
          child: Center(
            child: icon != null
                ? Icon(icon, color: Colors.grey[600], size: 24)
                : Text(
                    digit.toString(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
