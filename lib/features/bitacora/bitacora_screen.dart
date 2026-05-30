import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

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
  bool _isLoadingMore = false;
  bool _isFormValid = false;
  double _progressValue = 0.0;

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
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
}
        });
      }
    });
    
    _checkConnectivity();
    _setupValidationListeners();
  }

  void _setupValidationListeners() {
    _observacionesController.addListener(_validateForm);
    // Add listeners to other important fields if needed
  }

  void _validateForm() {
    final isValid = _observacionesController.text.trim().isNotEmpty;
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _refreshForm() async {
    // Reset form to initial state
    setState(() {
      _huboIncidente = false;
      _tipoIncidente = null;
      _incidenteController.clear();
      _observacionesController.clear();
      _recomendacionesController.clear();
      _comentariosController.clear();
      _fotosCampo.clear();
      _calidadServicio = 3;
      _coordinacion = 3;
      _atencion = 3;
      _fotoRostro = null;
      _isFormValid = false;
    });
  }

  void _checkConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none);
      });
    });
    
    // Initial check
    _connectivity.checkConnectivity().then((result) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _incidenteController.dispose();
    _observacionesController.dispose();
    _recomendacionesController.dispose();
    _comentariosController.dispose();
    _formScrollController.dispose();
    _connectivitySubscription?.cancel();
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
      _uploadStatus = 'Validando información...';
      _progressValue = 0.1;
    });

    try {
      // Simulate validation progress
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _uploadStatus = 'Preparando datos...';
        _progressValue = 0.3;
      });

      final firmaBytes = await _signatureKey.currentState?.getBytes();
      String? firmaDataUri;
      File? firmaFile;
      if (firmaBytes != null && firmaBytes.isNotEmpty) {
        firmaDataUri = 'data:image/png;base64,${base64Encode(firmaBytes)}';
        final backupDir = await _getBackupDir();
        firmaFile = File('${backupDir.path}/firma_temp_${DateTime.now().millisecondsSinceEpoch}.png');
        await firmaFile.writeAsBytes(firmaBytes);
      }

      if (!mounted) return;
      setState(() {
        _uploadStatus = 'Procesando fotos...';
        _progressValue = 0.5;
      });

      String? rostroDataUri;
      if (_fotoRostro != null) {
        rostroDataUri = await _fileToDataUri(_fotoRostro!);
      }

      final fotosCampoDataUris = <String>[];
      for (final foto in _fotosCampo) {
        final uri = await _fileToDataUri(foto);
        if (uri != null) fotosCampoDataUris.add(uri);
      }

      if (!mounted) return;
      setState(() {
        _uploadStatus = 'Generando ID único...';
        _progressValue = 0.7;
      });

      if (!mounted) return;
      setState(() {
        _uploadStatus = "Obteniendo ubicación actual...";
        _progressValue = 0.75;
      });
      if (!mounted) return;
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final coordFin = "(${position.latitude},${position.longitude})";
      final fechaFin = DateTime.now().toUtc().toIso8601String();

      final syncId = const Uuid().v4();

      final bitacora = Bitacora(
        tipo: 'beneficiario',
        beneficiarioId: _beneficiario?.id,
        fechaInicio: DateTime.now().toUtc().toIso8601String(),
        coordInicio: _coordInicio,
        coordFin: coordFin,
        fechaFin: fechaFin,
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
        if (!mounted) return;
        setState(() {
          _uploadStatus = 'Guardando localmente...';
          _progressValue = 0.9;
        });

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
        setState(() {
          _uploadStatus = 'Guardado completado';
          _progressValue = 1.0;
        });

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        context.go('/bitacora-success', extra: {'offline': true});
        return;
      }

      final api = ApiService(ref.read(authProvider.notifier));

      if (!mounted) return;
      setState(() => _uploadStatus = 'Conectando al servidor...');

      final response = await api.crearBitacora(bitacora.toBody());
      final bitacoraId = response['id']?.toString();

      if (bitacoraId == null) {
        throw SaderhException('No se recibió ID de bitácora del servidor');
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
      setState(() => _uploadStatus = 'Bitácora registrada correctamente');

      await NotificationService.showBitacoraSuccess(
        beneficiario: _beneficiario?.nombre ?? 'Bitácora',
      );

      if (!mounted) return;
      context.go('/bitacora-success', extra: {'offline': false});
    } on SaderhException catch (e) {
      if (!mounted) return;
      
      // Show specific error message based on exception type
      String errorMessage;
      if (e is NoInternetException) {
        errorMessage = 'No hay conexión a internet. La bitácora se guardará localmente.';
      } else if (e is TimeoutException) {
        errorMessage = 'Tiempo de espera agotado. Verifique su conexión e intente nuevamente.';
      } else if (e is AuthException) {
        errorMessage = 'Error de autenticación. Por favor, inicie sesión nuevamente.';
      } else if (e is ServerException) {
        errorMessage = 'Error del servidor. Intente nuevamente en unos minutos.';
      } else {
        errorMessage = e.message;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Still save offline as fallback
      final syncId = const Uuid().v4();
      final bitacora = Bitacora(
        tipo: 'beneficiario',
        beneficiarioId: _beneficiario?.id,
        fechaInicio: DateTime.now().toUtc().toIso8601String(),
        coordInicio: _coordInicio,
        coordFin: coordFin,
        fechaFin: fechaFin,
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
    } catch (e) {
      if (!mounted) return;
      
      // Handle any other unexpected errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: ${e.toString()}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Still save offline as fallback
      final syncId = const Uuid().v4();
      final bitacora = Bitacora(
        tipo: 'beneficiario',
        beneficiarioId: _beneficiario?.id,
        fechaInicio: DateTime.now().toUtc().toIso8601String(),
        coordInicio: _coordInicio,
        coordFin: coordFin,
        fechaFin: fechaFin,
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
      if (mounted) {
        setState(() {
          _isSaving = false;
          _progressValue = 0.0;
        });
      }
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
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _isSaving ? null : () => context.go('/dashboard'),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1A1A2E)),
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
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels == notification.metrics.maxScrollExtent &&
              !_isLoadingMore) {
            // Load more photos if needed (for future enhancement)
          }
          return false;
        },
        child: _isSaving
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        backgroundColor: AppColors.guinda.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.guinda),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      'No cierres la aplicación mientras se guarda la bitácora',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshForm,
                child: SingleChildScrollView(
                  controller: _formScrollController,
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Incidente', Icons.warning_amber, _buildIncidenteSection()),
                      const SizedBox(height: 20),
                      _buildSection('Observaciones', Icons.edit_note, _buildObservacionesSection()),
                      const SizedBox(height: 20),
                      _buildSection('Evidencias fotográficas', Icons.camera_alt, _buildEvidenciasSection()),
                      const SizedBox(height: 20),
                      _buildSection('Evaluación del servicio', Icons.star, _buildEvaluacionSection()),
                      const SizedBox(height: 20),
                      _buildSection('Validación de identidad', Icons.verified_user, _buildValidacionSection()),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.guinda.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.guinda, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
        const Text(
          '¿Hubo algún incidente durante la visita?',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        ToggleButtons(
          borderRadius: BorderRadius.circular(12),
          selectedBorderColor: AppColors.guinda,
          selectedColor: Colors.white,
          fillColor: AppColors.guinda.withValues(alpha: 0.1),
          color: Colors.grey[600]!,
          splashColor: AppColors.guinda.withValues(alpha: 0.1),
          highlightColor: AppColors.guinda.withValues(alpha: 0.05),
          isSelected: [_huboIncidente == false, _huboIncidente == true],
          onPressed: (index) {
            setState(() {
              _huboIncidente = index == 1;
              if (!_huboIncidente) {
                _tipoIncidente = null;
                _incidenteController.clear();
              }
            });
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text('No', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, size: 20),
                  SizedBox(width: 8),
                  Text('Sí', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        if (_huboIncidente) ...[
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Tipo de incidente',
            hint: 'Seleccione el tipo',
            prefixIcon: Icons.category,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tipoIncidente,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(Icons.category, color: Colors.grey[400]),
            ),
            items: ['Accidente', 'Conflicto', 'Daño material', 'Otro']
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _tipoIncidente = v),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Descripción del incidente',
            hint: 'Describa lo que sucedió',
            prefixIcon: Icons.description,
            maxLines: 3,
            controller: _incidenteController,
          ),
        ],
      ],
    );
  }

  Widget _buildObservacionesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Observaciones de la visita *',
          hint: 'Describe el resultado de la visita técnica...',
          maxLines: 5,
          controller: _observacionesController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Recomendaciones',
          maxLines: 3,
          controller: _recomendacionesController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Comentarios del beneficiario',
          maxLines: 2,
          controller: _comentariosController,
        ),
      ],
    );
  }

  Widget _buildEvidenciasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Fotos de campo',
          hint: '${_fotosCampo.length}/10 fotos',
          prefixIcon: Icons.image,
        ),
        const SizedBox(height: 12),
        if (_fotosCampo.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fotosCampo.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_fotosCampo[i].path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _fotosCampo.removeAt(i)),
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
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _fotosCampo.length >= 10 ? null : () => _addFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Tomar foto', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _fotosCampo.length >= 10 ? null : () => _addFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Seleccionar foto', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        _buildRatingRow('Calidad del servicio', _calidadServicio, (v) => setState(() => _calidadServicio = v)),
        const SizedBox(height: 24),
        _buildRatingRow('Coordinación', _coordinacion, (v) => setState(() => _coordinacion = v)),
        const SizedBox(height: 24),
        _buildRatingRow('Atención', _atencion, (v) => setState(() => _atencion = v)),
      ],
    );
  }

  Widget _buildRatingRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final isActive = index < value;
            return GestureDetector(
              onTap: () => onChanged(index + 1),
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.guinda : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.star,
                  size: 16,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$value/5',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidacionSection() {
    final rostroTomada = _fotoRostro != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Foto del rostro del beneficiario',
          hint: 'Requerida para validar identidad',
          prefixIcon: Icons.face,
        ),
        const SizedBox(height: 16),
        _buildPhotoPreview(
          foto: _fotoRostro,
          onTake: () => _tomarRostro(ImageSource.camera),
          onGallery: () => _tomarRostro(ImageSource.gallery),
        ),
        const SizedBox(height: 24),
        SignatureWidget(
          key: _signatureKey,
          enabled: rostroTomada,
          onChanged: (_) {},
        ),
        if (!rostroTomada)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Toma la foto del rostro primero para habilitar la firma',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

  Widget _buildTextField({
    required String label,
    String? hint,
    IconData? prefixIcon,
    int maxLines = 1,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[400]) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.guinda, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: (_isSaving || !_isFormValid) ? null : _save,
        icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.save_as, size: 20),
        label: Text(
          _isSaving ? 'Guardando...' : 'Guardar bitácora',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.guinda,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          disabledBackgroundColor: AppColors.guinda.withValues(alpha: 0.3),
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
