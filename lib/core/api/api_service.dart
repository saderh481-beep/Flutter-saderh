import 'package:dio/dio.dart';

import '../auth/auth_provider.dart';
import 'dio_client.dart';
import 'api_endpoints.dart';
import '../../core/exceptions/app_exceptions.dart';

class ApiService {
  late final DioClient _client;
  final AuthProvider _authProvider;

  ApiService(this._authProvider) {
    _client = DioClient(_authProvider);
  }

  Dio get dio => _client.dio;

  // --- Auth ---

  Future<Map<String, dynamic>> login(String codigo) async {
    try {
      final response = await dio.post(
        ApiEndpoints.authLogin,
        data: {'codigo': codigo},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await dio.post(ApiEndpoints.authLogout);
    } catch (_) {}
  }

  Future<bool> checkHealth() async {
    try {
      final response = await dio.get(ApiEndpoints.health);
      final data = response.data as Map<String, dynamic>;
      return data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  // --- Beneficiarios ---

  Future<List<Map<String, dynamic>>> getMisBeneficiarios() async {
    try {
      final response = await dio.get(ApiEndpoints.misBeneficiarios);
      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map<String, dynamic>) {
        final list = data['beneficiarios'] as List<dynamic>? ??
                     data['data'] as List<dynamic>? ??
                     [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> crearBeneficiario({
    required String nombreCompleto,
    required String municipio,
    required String localidad,
    required String telefonoContacto,
    String? curp,
    String? folioSaderh,
    String? cadenaProductiva,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.beneficiarios,
        data: {
          'nombre_completo': nombreCompleto,
          'municipio': municipio,
          'localidad': localidad,
          'telefono_contacto': telefonoContacto,
          if (curp != null) 'curp': curp,
          if (folioSaderh != null) 'folio_saderh': folioSaderh,
          if (cadenaProductiva != null) 'cadena_productiva': cadenaProductiva,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['data'] as Map<String, dynamic>? ?? data;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> getBeneficiario(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.beneficiarioPorId(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Actividades ---

  Future<List<Map<String, dynamic>>> getMisActividades() async {
    try {
      final response = await dio.get(ApiEndpoints.misActividades);
      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map<String, dynamic>) {
        final list = data['actividades'] as List<dynamic>? ??
                     data['data'] as List<dynamic>? ??
                     [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Asignaciones ---

  Future<Map<String, dynamic>> getAsignaciones() async {
    try {
      final response = await dio.get(ApiEndpoints.asignaciones);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is List) {
        return {'asignaciones': data};
      }
      return {};
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Cadenas Productivas ---

  Future<List<Map<String, dynamic>>> getCadenasProductivas() async {
    try {
      final response = await dio.get(ApiEndpoints.cadenasProductivas);
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Localidades ---

  Future<List<Map<String, dynamic>>> getLocalidades({String? municipio}) async {
    try {
      final query = municipio != null ? {'municipio': municipio} : null;
      final response = await dio.get(ApiEndpoints.localidades, queryParameters: query);
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Bitacoras ---

  Future<List<Map<String, dynamic>>> getBitacoras({
    int limit = 50,
    int offset = 0,
    String? estado,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (estado != null) params['estado'] = estado;
      final response = await dio.get(
        ApiEndpoints.bitacoras,
        queryParameters: params,
      );
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> getBitacora(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.bitacoraPorId(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getBitacorasPorBeneficiario(String beneficiarioId) async {
    try {
      final response = await dio.get(ApiEndpoints.bitacorasPorBeneficiario(beneficiarioId));
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getBitacorasPorActividad(String actividadId) async {
    try {
      final response = await dio.get(ApiEndpoints.bitacorasPorActividad(actividadId));
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> crearBitacora(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(ApiEndpoints.bitacoras, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> actualizarBitacora(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.bitacoraPorId(id),
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> cerrarBitacora(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.cerrarBitacora(id),
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<void> eliminarBitacora(String id) async {
    try {
      await dio.delete(ApiEndpoints.bitacoraPorId(id));
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<int> getBitacorasPendientes() async {
    try {
      final response = await dio.get(ApiEndpoints.bitacorasContador);
      final data = response.data as Map<String, dynamic>;
      return data['pendientes'] as int? ?? 0;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Fotos / Evidencias (multipart) ---

  Future<Map<String, dynamic>> subirFotoRostro({
    required String bitacoraId,
    required String filePath,
  }) async {
    return _subirArchivo(
      endpoint: ApiEndpoints.fotoRostroUpload(bitacoraId),
      fieldName: 'foto',
      filePath: filePath,
    );
  }

  Future<Map<String, dynamic>> subirFirma({
    required String bitacoraId,
    required String filePath,
  }) async {
    return _subirArchivo(
      endpoint: ApiEndpoints.firmaUpload(bitacoraId),
      fieldName: 'firma',
      filePath: filePath,
    );
  }

  Future<Map<String, dynamic>> subirFotosCampo({
    required String bitacoraId,
    required List<String> filePaths,
  }) async {
    try {
      final formData = FormData();
      for (final path in filePaths) {
        formData.files.add(MapEntry(
          'fotos',
          await MultipartFile.fromFile(path, filename: path.split('/').last),
        ));
      }
      final response = await dio.post(
        ApiEndpoints.fotosCampoUpload(bitacoraId),
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // Evidencias por URL directa
  Future<Map<String, dynamic>> saveFotoRostroUrl({
    required String bitacoraId,
    required String url,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.fotoRostroUrl(bitacoraId),
        data: {'url': url},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> saveFirmaUrl({
    required String bitacoraId,
    required String url,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.firmaUrl(bitacoraId),
        data: {'url': url},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> saveFotosCampoUrls({
    required String bitacoraId,
    required List<String> urls,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.fotosCampoUrls(bitacoraId),
        data: {'urls': urls},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // Consulta de evidencias
  Future<String?> getFotoRostroUrl(String bitacoraId) async {
    try {
      final response = await dio.get(ApiEndpoints.fotoRostroQuery(bitacoraId));
      return (response.data as Map<String, dynamic>)['url'] as String?;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<String?> getFirmaUrl(String bitacoraId) async {
    try {
      final response = await dio.get(ApiEndpoints.firmaQuery(bitacoraId));
      return (response.data as Map<String, dynamic>)['url'] as String?;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<List<String>> getFotosCampoUrls(String bitacoraId) async {
    try {
      final response = await dio.get(ApiEndpoints.fotosCampoQuery(bitacoraId));
      return ((response.data as Map<String, dynamic>)['urls'] as List<dynamic>?)
              ?.cast<String>() ??
          [];
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> deleteFotosCampoIdx({
    required String bitacoraId,
    required int index,
  }) async {
    try {
      final response = await dio.delete(
        ApiEndpoints.fotosCampoDeleteIdx(bitacoraId, index),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Files API (servicio separado) ---

  Future<Map<String, dynamic>> uploadToFilesApi({
    required String endpoint,
    required String filePath,
    String? bitacoraId,
    String? tecnicoId,
  }) async {
    try {
      final filesApiDio = Dio(BaseOptions(
        baseUrl: ApiEndpoints.filesApiBase,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final formData = FormData();
      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      ));
      if (bitacoraId != null) formData.fields.add(MapEntry('bitacora_id', bitacoraId));
      if (tecnicoId != null) formData.fields.add(MapEntry('tecnico_id', tecnicoId));

      final response = await filesApiDio.post(endpoint, data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Sync ---

  Future<Map<String, dynamic>> syncOperaciones(
    List<Map<String, dynamic>> operaciones,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.sync,
        data: {'operaciones': operaciones},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> syncDelta(String? ultimoSync) async {
    try {
      final params = <String, dynamic>{};
      if (ultimoSync != null) params['ultimo_sync'] = ultimoSync;
      final response = await dio.get(
        ApiEndpoints.syncDelta,
        queryParameters: params,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> sincronizarOffline(
    List<String> syncIds,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.syncOffline,
        data: {'sync_ids': syncIds},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> getSyncDebug() async {
    try {
      final response = await dio.get(ApiEndpoints.syncDebug);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Notificaciones ---

  Future<List<Map<String, dynamic>>> getNotificaciones() async {
    try {
      final response = await dio.get(ApiEndpoints.notificaciones);
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<void> marcarNotificacionLeida(String id) async {
    try {
      await dio.patch(ApiEndpoints.notificacionLeer(id));
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  // --- Privados ---

  Future<Map<String, dynamic>> _subirArchivo({
    required String endpoint,
    required String fieldName,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
      final response = await dio.post(endpoint, data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  void _handleAuthError(DioException e) {
    final exception = ExceptionHandler.handleException(e);
    if (exception is AuthException) {
      _authProvider.logout();
    }
    throw exception;
  }
}
