class Actividad {
  final String id;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Actividad({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.activo = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Actividad.fromJson(Map<String, dynamic> json) {
    return Actividad(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'activo': activo,
        'created_by': createdBy,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
