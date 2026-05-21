import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/api/api_service.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/offline/hive_service.dart';
import '../../core/offline/sync_service.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/local_data.dart';
import '../../core/theme/app_colors.dart';

import '../../shared/models/beneficiario.dart';
import '../../shared/models/actividad.dart';
import '../../shared/widgets/bubble_bottom_nav.dart';
import '../../shared/widgets/offline_badge.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isOffline = false;
  final _beneficiarios = <Beneficiario>[];
  final _actividades = <Actividad>[];
  int _currentTab = 0;
  int _pendingCount = 0;
  int _bitacorasCount = 0;
  String? _error;

  final _nombreCtrl = TextEditingController();
  String? _selectedMunicipio;
  final _localidadCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _curpCtrl = TextEditingController();
  bool _isCreating = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _generatedFolio = '';

  static const _municipiosHidalgo = [
    'Acatlan', 'Acaxochitlan', 'Actopan', 'Agua Blanca de Iturbide',
    'Ajacuba', 'Alfajayucan', 'Almoloya', 'Apan', 'El Arenal',
    'Atitalaquia', 'Atlapexco', 'Atotonilco de Tula', 'Atotonilco el Grande',
    'Atzalan', 'Cuautepec de Hinojosa', 'Chapantongo', 'Chapulhuacan',
    'Chilcuautla', 'Eloxochitlan', 'Emiliano Zapata', 'Epazoyucan',
    'Francisco I. Madero', 'Huasca de Ocampo', 'Huautla', 'Huazalingo',
    'Huehuetla', 'Huejutla de Reyes', 'Huichapan', 'Ixmiquilpan',
    'Jacala', 'Jaltocan', 'Juarez Hidalgo', 'Krall', 'Lolotla',
    'Metepec', 'San Agustin Metzquititlan', 'Metztitlan', 'Mineral del Chico',
    'Mineral del Monte', 'La Mision', 'Mixquiahuala de Juarez', 'Molango de Escamilla',
    'Nicolas Flores', 'Nopala de Villagran', 'Omitlan de Juarez', 'San Felipe Orizatlan',
    'Pacula', 'Pachuca de Soto', 'Pisaflores', 'Progreso de Obregon',
    'Mineral de la Reforma', 'San Agustin Tlaxiaca', 'San Bartolo Tutotepec',
    'San Salvador', 'Santiago de Anaya', 'Santiago Tulantepec',
    'Singuilucan', 'Tasquillo', 'Tecozautla', 'Tenango de Doria',
    'Tepeapulco', 'Tepehuacan de Guerrero', 'Tepeji del Rio de Ocampo',
    'Tepetitlan', 'Tetepango', 'Tezontepec de Aldama', 'Tianguistengo',
    'Tizayuca', 'Tlahuelilpan', 'Tlahuiltepa', 'Tlanalapa', 'Tlanchinol',
    'Tlaxcoapan', 'Tolcayuca', 'Tula de Allende', 'Tulancingo de Bravo',
    'Villa de Tezontepec', 'Xochiatipan', 'Xochicoatlan', 'Yahualica',
    'Zacualtipan de Angeles', 'Zapotlan de Juarez', 'Zempoala', 'Zimapan',
  ];

  @override
  void initState() {
    super.initState();
    _generateFolio();
    _loadData();
    _checkConnectivity();
    _loadPendingCount();
    _loadBitacorasCount();
  }

  void _generateFolio() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final random = (1000 + (now.millisecondsSinceEpoch % 9000)).toString();
    _generatedFolio = 'SADERH-$year$month-$random';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _localidadCtrl.dispose();
    _telefonoCtrl.dispose();
    _curpCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() => _isOffline = result.contains(ConnectivityResult.none));
    Connectivity().onConnectivityChanged.listen((r) {
      if (!mounted) return;
      setState(() => _isOffline = r.contains(ConnectivityResult.none));
    });
  }

  Future<void> _loadPendingCount() async {
    final count = await HiveService.pendingCount();
    if (!mounted) return;
    setState(() => _pendingCount = count);
  }

  Future<void> _loadBitacorasCount() async {
    try {
      final api = ApiService(ref.read(authProvider.notifier));
      final count = await api.getBitacorasPendientes();
      if (!mounted) return;
      setState(() => _bitacorasCount = count);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService(ref.read(authProvider.notifier));
      final result = await api.getAsignaciones();

      final beneficiarios = <Beneficiario>[];
      final actividades = <Actividad>[];

      final asignaciones = result['asignaciones'] as List<dynamic>?;
      if (asignaciones != null) {
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
      }

      if (beneficiarios.isEmpty && actividades.isEmpty) {
        final directBenef = await api.getMisBeneficiarios();
        for (final b in directBenef) {
          beneficiarios.add(Beneficiario.fromJson(b));
        }

        final directAct = await api.getMisActividades();
        for (final a in directAct) {
          actividades.add(Actividad.fromJson(a));
        }
      }

      if (beneficiarios.isNotEmpty || actividades.isNotEmpty) {
        await LocalData.saveFromApi(
          beneficiarios: beneficiarios,
          actividades: actividades.map((e) => e.toJson()).toList(),
        );
      }

      if (!mounted) return;
      setState(() {
        _beneficiarios..clear()..addAll(beneficiarios);
        _actividades..clear()..addAll(actividades);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final localBenef = await LocalData.getBeneficiarios();
      final localAct = await LocalData.getActividades();
      setState(() {
        _beneficiarios..clear()..addAll(localBenef);
        _actividades..clear()..addAll(
          localAct.map((e) => Actividad.fromJson(e)).toList(),
        );
        _error = 'Sin conexion. Datos locales.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFromApi() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final api = ApiService(ref.read(authProvider.notifier));
      final result = await api.getAsignaciones();

      final beneficiarios = <Beneficiario>[];
      final actividades = <Actividad>[];

      final asignaciones = result['asignaciones'] as List<dynamic>?;
      if (asignaciones != null) {
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
      }

      if (beneficiarios.isEmpty && actividades.isEmpty) {
        final directBenef = await api.getMisBeneficiarios();
        for (final b in directBenef) {
          beneficiarios.add(Beneficiario.fromJson(b));
        }

        final directAct = await api.getMisActividades();
        for (final a in directAct) {
          actividades.add(Actividad.fromJson(a));
        }
      }

      if (beneficiarios.isNotEmpty || actividades.isNotEmpty) {
        await LocalData.saveFromApi(
          beneficiarios: beneficiarios,
          actividades: actividades.map((e) => e.toJson()).toList(),
        );
      }

      if (!mounted) return;
      setState(() {
        _beneficiarios..clear()..addAll(beneficiarios);
        _actividades..clear()..addAll(actividades);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al sincronizar')),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _syncPending() async {
    if (_pendingCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay bitacoras pendientes')),
      );
      return;
    }

    try {
      final api = ApiService(ref.read(authProvider.notifier));
      final sync = SyncService(api);
      final result = await sync.syncAll();

      await _loadPendingCount();
      await _loadBitacorasCount();

      if (!mounted) return;

      if (result.synced > 0) {
        await NotificationService.showSyncComplete(result.synced);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.synced} bitacoras sincronizadas')),
        );
      }

      if (result.errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errores: ${result.errors.length}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de sincronizacion: $e')),
      );
    }
  }

  Future<void> _crearBeneficiario() async {
    if (_nombreCtrl.text.trim().isEmpty ||
        _selectedMunicipio == null ||
        _localidadCtrl.text.trim().isEmpty ||
        _telefonoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final api = ApiService(ref.read(authProvider.notifier));
      await api.crearBeneficiario(
        nombreCompleto: _nombreCtrl.text.trim(),
        municipio: _selectedMunicipio!,
        localidad: _localidadCtrl.text.trim(),
        telefonoContacto: _telefonoCtrl.text.trim(),
        curp: _curpCtrl.text.trim().isEmpty ? null : _curpCtrl.text.trim(),
        folioSaderh: _generatedFolio,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beneficiario registrado')),
      );
      _nombreCtrl.clear();
      setState(() => _selectedMunicipio = null);
      _localidadCtrl.clear();
      _telefonoCtrl.clear();
      _curpCtrl.clear();
      _generateFolio();
      await _refreshFromApi();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  List<Beneficiario> get _filteredBeneficiarios {
    if (_searchQuery.isEmpty) return _beneficiarios;
    return _beneficiarios.where((b) {
      final query = _searchQuery.toLowerCase();
      return b.nombre.toLowerCase().contains(query) ||
             b.nombreCompleto.toLowerCase().contains(query) ||
             b.municipio.toLowerCase().contains(query) ||
             (b.curp?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Buenos dias' : now.hour < 18 ? 'Buenas tardes' : 'Buenas noches';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth, greeting),
            if (_error != null) _buildErrorBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildInicioTab(),
                  _buildVisitasTab(),
                  _buildCrearTab(),
                  _buildPerfilTab(auth),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BubbleBottomNav(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        pendingCount: _pendingCount,
      ),
    );
  }

  Widget _buildHeader(AuthState auth, String greeting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.nombre ?? 'Tecnico',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          OfflineBadge(isOffline: _isOffline),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go('/historial'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.guinda.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Icon(Icons.history, color: AppColors.guinda, size: 22),
                  if (_bitacorasCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.dorado,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          InkWell(
            onTap: _loadData,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.refresh, size: 18, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInicioTab() {
    return RefreshIndicator(
      onRefresh: _refreshFromApi,
      color: AppColors.guinda,
      child: _isLoading
          ? _buildShimmer()
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'Mis beneficiarios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.guinda.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_filteredBeneficiarios.length}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.guinda,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                _filteredBeneficiarios.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(Icons.people_outline, 'Sin beneficiarios'),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.only(bottom: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final b = _filteredBeneficiarios[i];
                              return _BeneficiarioCard(
                                beneficiario: b,
                                index: i,
                                onTap: () => context.go('/beneficiario/${b.id}', extra: b),
                              );
                            },
                            childCount: _filteredBeneficiarios.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar beneficiario...',
          hintStyle: const TextStyle(color: AppColors.gray400),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.guinda, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.people,
          label: 'Beneficiarios',
          value: _beneficiarios.length.toString(),
          gradient: [AppColors.guinda, AppColors.guindaMid],
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.assignment,
          label: 'Actividades',
          value: _actividades.length.toString(),
          gradient: [AppColors.doradoDark, AppColors.dorado],
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.pending_actions,
          label: 'Pendientes',
          value: _pendingCount.toString(),
          gradient: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.gray100,
      highlightColor: AppColors.gray50,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (AppColors.guinda).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppColors.guinda),
          ),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: AppColors.gray500, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildVisitasTab() {
    return RefreshIndicator(
      onRefresh: _refreshFromApi,
      color: AppColors.guinda,
      child: _actividades.isEmpty
          ? _buildEmptyState(Icons.assignment_outlined, 'Sin actividades asignadas')
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _actividades.length,
              itemBuilder: (_, i) {
                final item = _actividades[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item.activo
                              ? [AppColors.success.withValues(alpha: 0.2), AppColors.success.withValues(alpha: 0.05)]
                              : [AppColors.dorado.withValues(alpha: 0.2), AppColors.dorado.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.activo ? Icons.check_circle : Icons.pause_circle_outlined,
                        color: item.activo ? AppColors.success : AppColors.dorado,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item.nombre,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.gray800),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.descripcion ?? 'Sin descripcion',
                        style: TextStyle(color: AppColors.gray500, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (item.activo ? AppColors.success : AppColors.dorado).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.activo ? 'Activa' : 'Inactiva',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.activo ? AppColors.success : AppColors.dorado,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (40 * i).ms, duration: 250.ms).slideY(begin: 0.05);
              },
            ),
    );
  }

  Widget _buildCrearTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.guinda.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nuevo beneficiario',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registra un nuevo beneficiario',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInputField(_nombreCtrl, Icons.person, 'Nombre completo *'),
          const SizedBox(height: 12),
          _buildInputField(_curpCtrl, Icons.badge, 'CURP', maxLength: 18),
          const SizedBox(height: 12),
          _buildMunicipioDropdown(),
          const SizedBox(height: 12),
          _buildInputField(_localidadCtrl, Icons.home, 'Localidad *'),
          const SizedBox(height: 12),
          _buildInputField(_telefonoCtrl, Icons.phone, 'Telefono *', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildFolioDisplay(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _crearBeneficiario,
              icon: _isCreating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.save, size: 20),
              label: Text(
                _isCreating ? 'Guardando...' : 'Guardar beneficiario',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.guinda,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    IconData icon,
    String label,
     {
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: TextStyle(color: AppColors.gray800),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
          prefixIcon: Icon(icon, color: AppColors.guinda, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildMunicipioDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMunicipio,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.location_city, color: AppColors.guinda, size: 20),
              const SizedBox(width: 12),
              const Text('Municipio *', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
            ],
          ),
          icon: Icon(Icons.arrow_drop_down, color: AppColors.guinda),
          dropdownColor: Colors.white,
          items: _municipiosHidalgo.map((m) {
            return DropdownMenuItem(
              value: m,
              child: Text(m, style: const TextStyle(fontSize: 13, color: AppColors.guinda)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedMunicipio = v),
        ),
      ),
    );
  }

  Widget _buildFolioDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.guinda.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.guinda.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: AppColors.guinda, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Folio SADERH',
                  style: const TextStyle(fontSize: 11, color: AppColors.doradoDark, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  _generatedFolio,
                  style: const TextStyle(fontSize: 14, color: AppColors.guinda, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(Icons.auto_awesome, size: 16, color: AppColors.doradoDark),
        ],
      ),
    );
  }

  Widget _buildPerfilTab(AuthState auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.nombre ?? 'Tecnico',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
                      ),
                      if (auth.rol != null)
                        Text(
                          auth.rol!,
                          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuCard([
            _MenuItem(icon: Icons.settings, title: 'Configuracion', subtitle: 'Almacenamiento', onTap: () => context.go('/config')),
            _MenuItem(icon: Icons.history, title: 'Historial de bitacoras', onTap: () => context.go('/historial')),
            _MenuItem(icon: Icons.sync, title: 'Sincronizar pendientes', subtitle: '$_pendingCount pendientes', onTap: _syncPending),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(item.icon, color: AppColors.guinda, size: 22),
                title: Text(item.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.gray800)),
                subtitle: item.subtitle != null ? Text(item.subtitle!, style: TextStyle(color: AppColors.gray400, fontSize: 13)) : null,
                trailing: Icon(Icons.chevron_right, color: AppColors.gray300, size: 20),
                onTap: item.onTap,
              ),
              if (i < items.length - 1) Divider(height: 1, indent: 52, color: AppColors.gray100),
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

class _BeneficiarioCard extends StatelessWidget {
  final Beneficiario beneficiario;
  final int index;
  final VoidCallback onTap;

  const _BeneficiarioCard({
    required this.beneficiario,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.guinda.withValues(alpha: 0.12), AppColors.guinda.withValues(alpha: 0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person, color: AppColors.guinda, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beneficiario.nombreCompleto.isNotEmpty
                            ? beneficiario.nombreCompleto
                            : beneficiario.nombre,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.gray800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: AppColors.doradoDark),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              beneficiario.municipio,
                              style: TextStyle(fontSize: 13, color: AppColors.gray500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.gray300, size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (25 * index).ms, duration: 200.ms).slideY(begin: 0.05);
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
