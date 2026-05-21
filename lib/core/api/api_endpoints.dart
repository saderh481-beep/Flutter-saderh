class ApiEndpoints {
  // Auth
  static const String authLogin = '/api/v1/auth/tecnico';
  static const String authLogout = '/api/v1/auth/logout';

  // Health
  static const String health = '/health';

  // Beneficiarios
  static const String misBeneficiarios = '/api/v1/mis-beneficiarios';
  static const String beneficiarios = '/api/v1/beneficiarios';

  // Actividades
  static const String misActividades = '/api/v1/mis-actividades';

  // Cadenas productivas
  static const String cadenasProductivas = '/api/v1/cadenas-productivas';

  // Localidades
  static const String localidades = '/api/v1/localidades';

  // Asignaciones
  static const String asignaciones = '/api/v1/asignaciones';

  // Bitacoras
  static const String bitacoras = '/api/v1/bitacoras';
  static const String bitacorasContador = '/api/v1/bitacoras/contador';

  // Notificaciones
  static const String notificaciones = '/api/v1/notificaciones';

  // Sync
  static const String sync = '/api/v1/sync';
  static const String syncDelta = '/api/v1/sync/delta';
  static const String syncOffline = '/api/v1/sync/sincronizar-offline';
  static const String syncDebug = '/api/v1/sync/debug';

  // Files API (servicio separado)
  static const String filesApiBase = 'https://campo-api-files-campo-saas.up.railway.app';
  static const String uploadFotoRostro = '/upload/foto-rostro';
  static const String uploadFirma = '/upload/firma';
  static const String uploadFotosCampo = '/upload/fotos-campo';

  // Helpers
  static String beneficiarioPorId(String id) => '$beneficiarios/$id';
  static String bitacoraPorId(String id) => '$bitacoras/$id';
  static String cerrarBitacora(String id) => '$bitacoras/$id/cerrar';
  static String bitacorasPorBeneficiario(String id) => '$bitacoras/beneficiario/$id';
  static String bitacorasPorActividad(String id) => '$bitacoras/actividad/$id';

  // Upload endpoints (multipart legacy)
  static String fotoRostroUpload(String id) => '$bitacoras/$id/foto-rostro';
  static String firmaUpload(String id) => '$bitacoras/$id/firma';
  static String fotosCampoUpload(String id) => '$bitacoras/$id/fotos-campo';

  // URL-based evidence endpoints
  static String fotoRostroUrl(String id) => '$bitacoras/$id/foto-rostro/url';
  static String firmaUrl(String id) => '$bitacoras/$id/firma/url';
  static String fotosCampoUrl(String id) => '$bitacoras/$id/fotos-campo/url';
  static String fotosCampoUrls(String id) => '$bitacoras/$id/fotos-campo/urls';

  // Evidence query endpoints
  static String fotoRostroQuery(String id) => '$bitacoras/$id/foto-rostro';
  static String firmaQuery(String id) => '$bitacoras/$id/firma';
  static String fotosCampoQuery(String id) => '$bitacoras/$id/fotos-campo';
  static String fotosCampoDeleteIdx(String id, int idx) => '$bitacoras/$id/fotos-campo/$idx';

  // Notificaciones
  static String notificacionLeer(String id) => '$notificaciones/$id/leer';

  // SSE Events
  static String events(String tecnicoId) => '/events/$tecnicoId';
}
