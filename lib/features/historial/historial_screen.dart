import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_service.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  final _bitacoras = <Map<String, dynamic>>[];
  bool _isLoading = true;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 50;
  String? _filterEstado;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
      _bitacoras.clear();
      _hasMore = true;
    });
    await _fetchBitacoras();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    setState(() => _offset += _limit);
    await _fetchBitacoras();
  }

  Future<void> _fetchBitacoras() async {
    try {
      final api = ApiService(ref.read(authProvider.notifier));
      final data = await api.getBitacoras(
        limit: _limit,
        offset: _offset,
        estado: _filterEstado,
      );

      if (!mounted) return;
      setState(() {
        _bitacoras.addAll(data);
        _isLoading = false;
        _hasMore = data.length >= _limit;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt.toLocal());
    } catch (_) {
      return dateStr;
    }
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
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Historial', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray800)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, size: 22, color: AppColors.gray600),
            onSelected: (value) {
              setState(() => _filterEstado = value == 'todas' ? null : value);
              _load();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'todas', child: Text('Todas')),
              const PopupMenuItem(value: 'borrador', child: Text('Borrador')),
              const PopupMenuItem(value: 'cerrada', child: Text('Cerradas')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.guinda,
        child: _isLoading && _bitacoras.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.guinda,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cargando bitacoras...',
                      style: TextStyle(
                        color: AppColors.gray500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : _bitacoras.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.guinda.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history,
                            size: 40,
                            color: AppColors.guinda,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sin bitacoras registradas',
                          style: TextStyle(
                            color: AppColors.gray500,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tus bitacoras apareceran aqui',
                          style: TextStyle(
                            color: AppColors.gray400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _bitacoras.length + (_hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= _bitacoras.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.guinda,
                                ),
                              ),
                            ),
                          );
                        }
                        final b = _bitacoras[i];
                        final cerrada = b['estado'] == 'cerrada';
                        final nombre = b['beneficiario_nombre'] as String? ??
                                       b['actividad_nombre'] as String? ??
                                       'Sin nombre';
                        final calificacion = b['calificacion'] as int? ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.gray100,
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: cerrada
                                              ? [AppColors.success.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0.05)]
                                              : [AppColors.warning.withValues(alpha: 0.15), AppColors.warning.withValues(alpha: 0.05)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        cerrada ? Icons.check_circle : Icons.edit_note,
                                        color: cerrada ? AppColors.success : AppColors.warning,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: AppColors.gray800,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 13,
                                                color: AppColors.gray400,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _formatDate(b['fecha_inicio']),
                                                style: const TextStyle(
                                                  color: AppColors.gray500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (calificacion > 0) ...[
                                                const SizedBox(width: 10),
                                                const Icon(
                                                  Icons.star,
                                                  size: 14,
                                                  color: AppColors.dorado,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$calificacion',
                                                  style: const TextStyle(
                                                    color: AppColors.dorado,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: cerrada
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        cerrada ? 'Cerrada' : 'Borrador',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: cerrada ? AppColors.success : AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
