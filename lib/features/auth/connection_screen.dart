import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_service.dart';
import '../../core/auth/secure_storage.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final url = await SecureStorage.getServerUrl();
    _controller.text = url;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  Future<void> _connect() async {
    final url = _controller.text.trim();
    if (!_isValidUrl(url)) {
      setState(() => _error = 'Ingresa una URL válida (https://...)');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await SecureStorage.saveServerUrl(url);

    final api = ApiService(ref.read(authProvider.notifier));
    final healthy = await api.checkHealth();

    if (!mounted) return;

    if (healthy) {
      context.go('/login');
    } else {
      setState(() {
        _error = 'No se pudo conectar al servidor. Verifica la URL.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.guinda.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_outlined, size: 40, color: AppColors.guinda),
              ),
              const SizedBox(height: 24),
              Text(
                'Configurar servidor',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dorado,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa la URL del servidor de SADERH',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://campo-api-app-campo-saas.up.railway.app',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  labelText: 'URL del servidor',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.link, color: AppColors.guinda),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.guinda, width: 2),
                  ),
                  errorText: _error,
                  errorStyle: const TextStyle(color: AppColors.danger),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _connect,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Conectar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
