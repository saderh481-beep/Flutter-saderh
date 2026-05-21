import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api/api_service.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/beneficiario.dart';

class BeneficiarioDetailScreen extends ConsumerStatefulWidget {
  final Beneficiario beneficiario;

  const BeneficiarioDetailScreen({super.key, required this.beneficiario});

  @override
  ConsumerState<BeneficiarioDetailScreen> createState() => _BeneficiarioDetailScreenState();
}

class _BeneficiarioDetailScreenState extends ConsumerState<BeneficiarioDetailScreen> {
  Position? _position;
  bool _isLocating = false;
  String? _locationError;
  List<Map<String, dynamic>> _bitacorasPrevias = [];
  bool _isLoadingBitacoras = true;

  @override
  void initState() {
    super.initState();
    _loadBitacorasPrevias();
  }

  Future<void> _loadBitacorasPrevias() async {
    try {
      final api = ApiService(ref.read(authProvider.notifier));
      final bitacoras = await api.getBitacorasPorBeneficiario(widget.beneficiario.id);
      if (!mounted) return;
      setState(() {
        _bitacorasPrevias = bitacoras;
        _isLoadingBitacoras = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingBitacoras = false);
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Activa el GPS para continuar';
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permiso de ubicacion denegado';
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permiso denegado permanentemente. Ve a Configuracion.';
          _isLocating = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      if (!mounted) return;
      setState(() {
        _position = pos;
        _isLocating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Error al obtener ubicacion: $e';
        _isLocating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.beneficiario;
    final nombre = b.nombreCompleto.isNotEmpty ? b.nombreCompleto : b.nombre;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(nombre),
            const SizedBox(height: 12),
            _buildInfoCard(b),
            const SizedBox(height: 12),
            _buildLocationCard(),
            const SizedBox(height: 12),
            _buildBitacorasCard(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String nombre) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.guinda, AppColors.guindaMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.beneficiario.municipio,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Beneficiario b) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Nombre', b.nombreCompleto.isNotEmpty ? b.nombreCompleto : b.nombre),
          if (b.curp != null) _buildInfoRow('CURP', b.curp!),
          _buildInfoRow('Municipio', b.municipio),
          if (b.localidad != null) _buildInfoRow('Localidad', b.localidad!),
          if (b.direccion != null) _buildInfoRow('Direccion', b.direccion!),
          if (b.cp != null) _buildInfoRow('C.P.', b.cp!),
          if (b.telefonoPrincipal != null) _buildInfoRow('Telefono', b.telefonoPrincipal!),
          if (b.telefonoSecundario != null) _buildInfoRow('Tel. secundario', b.telefonoSecundario!),
          if (b.folioSaderh != null) _buildInfoRow('Folio SADERH', b.folioSaderh!),
          if (b.cadenaProductiva != null) _buildInfoRow('Cadena productiva', b.cadenaProductiva!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF1A1A2E))),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu ubicacion',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            if (_position == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLocating ? null : _getLocation,
                  icon: _isLocating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.my_location, size: 16),
                  label: Text(_isLocating ? 'Obteniendo...' : 'Obtener ubicacion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.guinda,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            if (_locationError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_locationError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
                  ],
                ),
              ),
            if (_position != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        const Text('Ubicacion obtenida', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Lat: ${_position!.latitude.toStringAsFixed(6)}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    Text('Lng: ${_position!.longitude.toStringAsFixed(6)}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBitacorasCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Bitacoras previas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(width: 8),
                if (!_isLoadingBitacoras)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.guinda.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_bitacorasPrevias.length}',
                      style: const TextStyle(fontSize: 11, color: AppColors.guinda, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoadingBitacoras)
              const Center(child: CircularProgressIndicator())
            else if (_bitacorasPrevias.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Sin bitacoras anteriores',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              )
            else
              ..._bitacorasPrevias.take(3).map((bit) => _buildBitacoraPreview(bit)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBitacoraPreview(Map<String, dynamic> bit) {
    final cerrada = bit['estado'] == 'cerrada';
    final fechaInicio = bit['fecha_inicio'] as String?;
    String fechaStr = '';
    if (fechaInicio != null) {
      try {
        final dt = DateTime.parse(fechaInicio);
        fechaStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            cerrada ? Icons.check_circle : Icons.edit_note,
            color: cerrada ? AppColors.success : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fechaStr,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF1A1A2E)),
                ),
                Text(
                  cerrada ? 'Cerrada' : 'Borrador',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _position == null
            ? null
            : () => context.go('/bitacora', extra: {
                  'beneficiario': widget.beneficiario,
                  'lat': _position!.latitude,
                  'lng': _position!.longitude,
                }),
        icon: const Icon(Icons.edit_note, size: 18),
        label: const Text('Llenar bitacora', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.guinda,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
