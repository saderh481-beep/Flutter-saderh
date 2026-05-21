import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _urlKey = 'server_url';
  static const _codigoKey = 'tecnico_codigo';
  static const _nombreKey = 'tecnico_nombre';
  static const _rolKey = 'tecnico_rol';
  static const _idKey = 'tecnico_id';
  static const _biometriaKey = 'biometria_activa';

  static const defaultUrl =
      'https://campo-api-app-campo-saas.up.railway.app';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveServerUrl(String url) async {
    await _storage.write(key: _urlKey, value: url);
  }

  static Future<String> getServerUrl() async {
    final url = await _storage.read(key: _urlKey);
    return url ?? defaultUrl;
  }

  static Future<void> saveTecnico({
    required String id,
    required String nombre,
    required String rol,
    required String codigo,
  }) async {
    await Future.wait([
      _storage.write(key: _idKey, value: id),
      _storage.write(key: _nombreKey, value: nombre),
      _storage.write(key: _rolKey, value: rol),
      _storage.write(key: _codigoKey, value: codigo),
    ]);
  }

  static Future<Map<String, String?>> getTecnico() async {
    final results = await Future.wait([
      _storage.read(key: _idKey),
      _storage.read(key: _nombreKey),
      _storage.read(key: _rolKey),
      _storage.read(key: _codigoKey),
    ]);
    return {
      'id': results[0],
      'nombre': results[1],
      'rol': results[2],
      'codigo': results[3],
    };
  }

  static Future<bool> isBiometriaActiva() async {
    final val = await _storage.read(key: _biometriaKey);
    return val == 'true';
  }

  static Future<void> setBiometriaActiva(bool active) async {
    await _storage.write(key: _biometriaKey, value: active.toString());
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> hasUrl() async {
    final url = await _storage.read(key: _urlKey);
    return url != null && url.isNotEmpty;
  }
}
