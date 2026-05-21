import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_service.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/offline/hive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/beneficiario.dart';
import '../../shared/models/bitacora.dart';
import 'signature_widget.dart';

class BitacoraScreen extends ConsumerStatefulWidget {
  const BitacoraScreen({super.key});

  @override
  ConsumerState<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends ConsumerState<BitacoraScreen> {
  Beneficiario? _beneficiario;
  double? _lat;
  double? _lng;
  bool _isSaving = false;
  bool _isOffline = false;
  String? _uploadStatus;

  bool _huboIncidente = false;
  String? _tipoIncidente;
  final _incidenteController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _recomendacionesController = TextEditingController();
  final _comentariosController = TextEditingController();

  final List<XFile> _fotosCampo = [];
  int _calidadServicio = 3;
  int _coordinacion = 3;
  int _atencion = 3;

  XFile? _fotoRostro;
  final _signatureKey = GlobalKey<SignatureWidgetState>();
  final _picker = ImagePicker();
  String? _coordInicio;

  final _scrollKey = GlobalKey<ScaffoldState>();
  final _formScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (extra != null) {
        setState(() {
          _beneficiario = extra['beneficiario'] as Beneficiario?;
          _lat = extra['lat'] as double?;
          _lng = extra['lng'] as double?;
          if (_lat != null && _lng != null) {
            _coordInicio = '($_lat,$_lng)';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _incidenteController.dispose();
    _observacionesController.dispose();
    _recomendacionesController.dispose();
    _comentariosController.dispose();
    _formScrollController.dispose();
    super.dispose();
  }

  Future<String?> _fileToDataUri(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      final ext = file.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png') mimeType = 'image/png';
      if (ext == 'webp') mimeType = 'image/webp';
      return 'data:$mimeType;base64,$base64';
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _getBackupDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/SADERH_Bitacoras');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<void> _saveBitacoraBackup({
    required String bitacoraId,
    required Map<String, dynamic> data,
    required List<String> fotoPaths,
    String? rostroPath,
    String? firmaPath,
  }) async {
    try {
      final backupDir = await _getBackupDir();
      final bitacoraDir = Directory('${backupDir.path}/$bitacoraId');
      if (!await bitacoraDir.exists()) {
        await bitacoraDir.create(recursive: true);
      }

      final jsonFile = File('${bitacoraDir.path}/bitacora.json');
      await jsonFile.writeAsString(jsonEncode(data));

      for (int i = 0; i < fotoPaths.length; i++) {
        final src = File(fotoPaths[i]);
        if (await src.exists()) {
          await src.copy('${bitacoraDir.path}/campo_${i + 1}.jpg');
        }
      }

      if (rostroPath != null) {
        final src = File(rostroPath);
        if (await src.exists()) {
          await src.copy('${bitacoraDir.path}/rostro.jpg');
        }
      }

      if (firmaPath != null) {
        final src = File(firmaPath);
        if (await src.exists()) {
          await src.copy('${bitacoraDir.path}/firma.png');
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_observacionesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las observaciones son obligatorias')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadStatus = 'Guardando bitacora...';
    });

    try {
      final firmaBytes = await _signatureKey.currentState?.getBytes();
      String? firmaDataUri;
      File? firmaFile;
      if (firmaBytes != null && firmaBytes.isNotEmpty) {
        firmaDataUri = 'data:image/png;base64,${base64Encode(firmaBytes)}';
        final backupDir = await _getBackupDir();
        firmaFile = File('${backupDir.path}/firma_temp_${DateTime.now().millisecondsSinceEpoch}.png');
        await firmaFile.writeAsBytes(firmaBytes);
      }

      String? rostroDataUri;
      if (_fotoRostro != null) {
        rostroDataUri = await _fileToDataUri(_fotoRostro!);
      }

      final fotosCampoDataUris = <String>[];
      for (final foto in _fotosCampo) {
        final uri = await _fileToDataUri(foto);
        if (uri != null) fotosCampoDataUris.add(uri);
      }

      final syncId = const Uuid().v4();

      final bitacora = Bitacora(
        tipo: 'beneficiario',
        beneficiarioId: _beneficiario?.id,
        fechaInicio: DateTime.now().toUtc().toIso8601String(),
        coordInicio: _coordInicio,
        actividadesDesc: _observacionesController.text.trim(),
        recomendaciones: _recomendacionesController.text.trim().isEmpty
            ? null
            : _recomendacionesController.text.trim(),
        comentariosBeneficiario: _comentariosController.text.trim().isEmpty
            ? null
            : _comentariosController.text.trim(),
        calificacion: _calidadServicio,
        estado: 'cerrada',
        creadaOffline: _isOffline,
        syncId: syncId,
        fotoRostroUrl: rostroDataUri,
        firmaUrl: firmaDataUri,
        fotosCampo: fotosCampoDataUris,
      );

      final fotoPaths = _fotosCampo.map((f) => f.path).toList();

      if (_isOffline) {
        await HiveService.enqueue({
          'operacion': 'crear_bitacora',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'payload': bitacora.toBody(),
        });

        await _saveBitacoraBackup(
          bitacoraId: syncId,
          data: bitacora.toBody(),
          fotoPaths: fotoPaths,
          rostroPath: _fotoRostro?.path,
          firmaPath: firmaFile?.path,
        );

        if (!mounted) return;
        context.go('/bitacora-success', extra: {'offline': true});
        return;
      }

      final api = ApiService(ref.read(authProvider.notifier));

      if (!mounted) return;
      setState(() => _uploadStatus = 'Enviando bitacora al servidor...');

      final response = await api.crearBitacora(bitacora.toBody());
      final bitacoraId = response['id']?.toString();

      if (bitacoraId == null) {
        throw Exception('No se recibio ID de bitacora');
      }

      if (!mounted) return;
      setState(() => _uploadStatus = 'Guardando respaldo local...');

      await _saveBitacoraBackup(
        bitacoraId: bitacoraId,
        data: bitacora.toBody(),
        fotoPaths: fotoPaths,
        rostroPath: _fotoRostro?.path,
        firmaPath: firmaFile?.path,
      );

      if (!mounted) return;
      setState(() => _uploadStatus = 'Bitacora registrada correctamente');

      await NotificationService.showBitacoraSuccess(
        beneficiario: _beneficiario?.nombre ?? 'Bitacora',
      );

      if (!mounted) return;
      context.go('/bitacora-success', extra: {'offline': false});
    } catch (e) {
      if (!mounted) return;

      final syncId = const Uuid().v4();
      final bitacora = Bitacora(
        tipo: 'beneficiario',
        beneficiarioId: _beneficiario?.id,
        fechaInicio: DateTime.now().toUtc().toIso8601String(),
        coordInicio: _coordInicio,
        actividadesDesc: _observacionesController.text.trim(),
        recomendaciones: _recomendacionesController.text.trim().isEmpty
            ? null
            : _recomendacionesController.text.trim(),
        comentariosBeneficiario: _comentariosController.text.trim().isEmpty
            ? null
            : _comentariosController.text.trim(),
        calificacion: _calidadServicio,
        estado: 'cerrada',
        creadaOffline: true,
        syncId: syncId,
      );

      final fotoPaths = _fotosCampo.map((f) => f.path).toList();
      await HiveService.enqueue({
        'operacion': 'crear_bitacora',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'payload': bitacora.toBody(),
      });

      await _saveBitacoraBackup(
        bitacoraId: syncId,
        data: bitacora.toBody(),
        fotoPaths: fotoPaths,
        rostroPath: _fotoRostro?.path,
        firmaPath: null,
      );

      if (!mounted) return;
      context.go('/bitacora-success', extra: {'offline': true});
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _beneficiario?.nombreCompleto.isNotEmpty == true
        ? _beneficiario!.nombreCompleto
        : _beneficiario?.nombre ?? 'Bitacora';

    return Scaffold(
      key: _scrollKey,
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _isSaving ? null : () => context.go('/dashboard'),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Offline', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.guinda,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _uploadStatus ?? 'Guardando...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.guinda,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No cierres la aplicacion',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _formScrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Incidente', Icons.warning_amber, _buildIncidenteSection()),
                  const SizedBox(height: 12),
                  _buildSection('Observaciones', Icons.edit_note, _buildObservacionesSection()),
                  const SizedBox(height: 12),
                  _buildSection('Evidencias fotograficas', Icons.camera_alt, _buildEvidenciasSection()),
                  const SizedBox(height: 12),
                  _buildSection('Evaluacion del servicio', Icons.star, _buildEvaluacionSection()),
                  const SizedBox(height: 12),
                  _buildSection('Validacion de identidad', Icons.verified_user, _buildValidacionSection()),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.guinda.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.guinda, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildIncidenteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Hubo algun incidente durante la visita?',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('No'), icon: Icon(Icons.check_circle_outline, size: 18)),
            ButtonSegment(value: true, label: Text('Si'), icon: Icon(Icons.warning_amber, size: 18)),
          ],
          selected: {_huboIncidente},
          onSelectionChanged: (v) => setState(() => _huboIncidente = v.first),
        ),
        if (_huboIncidente) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _tipoIncidente,
            decoration: InputDecoration(
              labelText: 'Tipo de incidente',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: ['Accidente', 'Conflicto', 'Daño material', 'Otro']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _tipoIncidente = v),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _incidenteController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Descripcion del incidente',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildObservacionesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _observacionesController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Observaciones de la visita *',
            hintText: 'Describe el resultado de la visita tecnica...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _recomendacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Recomendaciones',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _comentariosController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Comentarios del beneficiario',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenciasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos de campo (${_fotosCampo.length}/10)',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 10),
        if (_fotosCampo.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fotosCampo.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_fotosCampo[i].path),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _fotosCampo.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _fotosCampo.length >= 10 ? null : () => _addFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Camara', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _fotosCampo.length >= 10 ? null : () => _addFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text('Galeria', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addFoto(ImageSource source) async {
    try {
      final foto = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (foto != null) {
        setState(() => _fotosCampo.add(foto));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar foto: $e')),
        );
      }
    }
  }

  Widget _buildEvaluacionSection() {
    return Column(
      children: [
        _starRating('Calidad del servicio', _calidadServicio, (v) => setState(() => _calidadServicio = v)),
        const Divider(height: 28),
        _starRating('Coordinacion', _coordinacion, (v) => setState(() => _coordinacion = v)),
        const Divider(height: 28),
        _starRating('Atencion', _atencion, (v) => setState(() => _atencion = v)),
      ],
    );
  }

  Widget _starRating(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ),
        Row(
          children: List.generate(5, (i) {
            final filled = i < value;
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: filled ? const Color(0xFFFFB800) : Colors.grey[300],
                  size: 26,
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 20,
          child: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E))),
        ),
      ],
    );
  }

  Widget _buildValidacionSection() {
    final rostroTomada = _fotoRostro != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto del rostro del beneficiario',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 10),
        _buildPhotoPreview(
          foto: _fotoRostro,
          placeholder: 'Foto de rostro',
          placeholderIcon: Icons.face,
          onTake: () => _tomarRostro(ImageSource.camera),
          onGallery: () => _tomarRostro(ImageSource.gallery),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        SignatureWidget(
          key: _signatureKey,
          enabled: rostroTomada,
          onChanged: (_) {},
        ),
        if (!rostroTomada)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Toma la foto del rostro primero para habilitar la firma',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoPreview({
    XFile? foto,
    required String placeholder,
    required IconData placeholderIcon,
    required VoidCallback onTake,
    required VoidCallback onGallery,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: foto != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(foto.path), fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _fotoRostro = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(placeholderIcon, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 6),
                      Text(placeholder, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTake,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Camara', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text('Galeria', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.save_as, size: 18),
        label: Text(
          _isSaving ? 'Guardando...' : 'Guardar bitacora',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.guinda,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _tomarRostro(ImageSource source) async {
    try {
      final foto = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (foto != null) {
        setState(() => _fotoRostro = foto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
