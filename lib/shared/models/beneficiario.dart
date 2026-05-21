class Beneficiario {
  final String id;
  final String idBeneficiario;
  final String nombre;
  final String nombreCompleto;
  final String? curp;
  final String municipio;
  final String? localidad;
  final String? direccion;
  final String? cp;
  final String? folioSaderh;
  final String? cadenaProductiva;
  final String? telefonoPrincipal;
  final String? telefonoSecundario;
  final String? coordParcela;
  final bool activo;

  Beneficiario({
    required this.id,
    required this.idBeneficiario,
    required this.nombre,
    required this.nombreCompleto,
    this.curp,
    required this.municipio,
    this.localidad,
    this.direccion,
    this.cp,
    this.folioSaderh,
    this.cadenaProductiva,
    this.telefonoPrincipal,
    this.telefonoSecundario,
    this.coordParcela,
    this.activo = true,
  });

  factory Beneficiario.fromJson(Map<String, dynamic> json) {
    return Beneficiario(
      id: json['id']?.toString() ?? '',
      idBeneficiario: json['id_beneficiario']?.toString() ?? '',
      nombre: json['nombre'] as String? ?? json['nombre_completo'] as String? ?? '',
      nombreCompleto: json['nombre_completo'] as String? ?? json['nombre'] as String? ?? '',
      curp: json['curp'] as String?,
      municipio: json['municipio'] as String? ?? '',
      localidad: json['localidad'] as String?,
      direccion: json['direccion'] as String?,
      cp: json['cp'] as String?,
      folioSaderh: json['folio_saderh'] as String?,
      cadenaProductiva: json['cadena_productiva'] as String?,
      telefonoPrincipal: json['telefono_principal'] as String?,
      telefonoSecundario: json['telefono_secundario'] as String?,
      coordParcela: json['coord_parcela'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_beneficiario': idBeneficiario,
        'nombre': nombre,
        'nombre_completo': nombreCompleto,
        'curp': curp,
        'municipio': municipio,
        'localidad': localidad,
        'direccion': direccion,
        'telefono_principal': telefonoPrincipal,
        'telefono_secundario': telefonoSecundario,
        'folio_saderh': folioSaderh,
        'cadena_productiva': cadenaProductiva,
        'coord_parcela': coordParcela,
        'activo': activo,
        'cp': cp,
      };
}
