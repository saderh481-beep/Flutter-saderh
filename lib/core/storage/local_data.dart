import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/beneficiario.dart';

class LocalData {
  LocalData._();

  static const _beneficiariosKey = 'local_beneficiarios';
  static const _actividadesKey = 'local_actividades';
  static const _historialKey = 'local_historial';
  static const _dataSeededKey = 'local_data_seeded';

  static Future<bool> isSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dataSeededKey) ?? false;
  }

  static Future<void> seedIfEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    final seeded = prefs.getBool(_dataSeededKey) ?? false;
    if (seeded) return;

    await prefs.setString(_beneficiariosKey, jsonEncode(_defaultBeneficiarios));
    await prefs.setString(_actividadesKey, jsonEncode(_defaultActividades));
    await prefs.setString(_historialKey, jsonEncode(_defaultHistorial));
    await prefs.setBool(_dataSeededKey, true);
  }

  static Future<void> saveFromApi({
    required List<Beneficiario> beneficiarios,
    required List<Map<String, dynamic>> actividades,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_beneficiariosKey, jsonEncode(beneficiarios.map((e) => e.toJson()).toList()));
    await prefs.setString(_actividadesKey, jsonEncode(actividades));
    await prefs.setBool(_dataSeededKey, true);
  }

  static Future<List<Beneficiario>> getBeneficiarios() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_beneficiariosKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Beneficiario.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveBeneficiarios(List<Beneficiario> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_beneficiariosKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<List<Map<String, dynamic>>> getActividades() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_actividadesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveActividades(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_actividadesKey, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historialKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_beneficiariosKey);
    await prefs.remove(_actividadesKey);
    await prefs.remove(_historialKey);
    await prefs.remove(_dataSeededKey);
    await prefs.remove('onboarding_completado');
    await prefs.remove('permisos_concedidos');
  }
}

const _defaultBeneficiarios = [
  {
    'id': '1', 'id_beneficiario': 'B001',
    'nombre': 'Juan Pérez López', 'nombre_completo': 'Juan Pérez López',
    'curp': 'PELJ800101HDFRRN01', 'municipio': 'Pachuca',
    'direccion': 'Calle Principal 123, Centro',
  },
  {
    'id': '2', 'id_beneficiario': 'B002',
    'nombre': 'María García Hernández', 'nombre_completo': 'María García Hernández',
    'curp': 'GAHM850523MDFRRN02', 'municipio': 'Tulancingo',
    'direccion': 'Av. Juárez 456, Doctores',
  },
  {
    'id': '3', 'id_beneficiario': 'B003',
    'nombre': 'Pedro Martínez Cruz', 'nombre_completo': 'Pedro Martínez Cruz',
    'curp': 'MACP750812HDFRRN03', 'municipio': 'Mineral de la Reforma',
    'direccion': 'Carretera Libre Km 5',
  },
  {
    'id': '4', 'id_beneficiario': 'B004',
    'nombre': 'Ana López Rivera', 'nombre_completo': 'Ana López Rivera',
    'curp': 'LORA900305MDFRRN04', 'municipio': 'Actopan',
    'direccion': 'Calle Hidalgo 78',
  },
  {
    'id': '5', 'id_beneficiario': 'B005',
    'nombre': 'Carlos Mendoza Ortiz', 'nombre_completo': 'Carlos Mendoza Ortiz',
    'curp': 'MEOC850618HDFRRN05', 'municipio': 'Huichapan',
    'direccion': 'Av. Independencia 234',
  },
];

const _defaultActividades = [
  {'id': 'A001', 'beneficiario': 'Juan Pérez López', 'tipo': 'Visita técnica', 'fecha': '22/05/2026', 'status': 'pendiente'},
  {'id': 'A002', 'beneficiario': 'María García Hernández', 'tipo': 'Seguimiento', 'fecha': '23/05/2026', 'status': 'pendiente'},
  {'id': 'A003', 'beneficiario': 'Pedro Martínez Cruz', 'tipo': 'Evaluación', 'fecha': '24/05/2026', 'status': 'completada'},
];

const _defaultHistorial = [
  {'beneficiario': 'Juan Pérez López', 'fecha': '19/05/2026', 'tipo': 'Visita técnica', 'status': 'sincronizada'},
  {'beneficiario': 'María García Hernández', 'fecha': '18/05/2026', 'tipo': 'Seguimiento', 'status': 'pendiente'},
  {'beneficiario': 'Pedro Martínez Cruz', 'fecha': '16/05/2026', 'tipo': 'Evaluación', 'status': 'sincronizada'},
];
