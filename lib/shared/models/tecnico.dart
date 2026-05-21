class Tecnico {
  final String id;
  final String nombre;
  final String rol;
  final String codigo;

  Tecnico({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.codigo,
  });

  factory Tecnico.fromJson(Map<String, dynamic> json, String codigo) {
    return Tecnico(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] as String? ?? '',
      rol: json['rol'] as String? ?? 'tecnico',
      codigo: codigo,
    );
  }
}
