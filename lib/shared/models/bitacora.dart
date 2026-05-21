class Bitacora {
  final String? id;
  final String tipo;
  final String? beneficiarioId;
  final String? actividadId;
  final String? cadenaProductivaId;
  final String fechaInicio;
  final String? fechaFin;
  final String? coordInicio;
  final String? coordFin;
  final String actividadesDesc;
  final String? recomendaciones;
  final String? comentariosBeneficiario;
  final bool coordinacionInterinst;
  final String? instanciaCoordinada;
  final String? propositoCoordinacion;
  final String? observacionesCoordinador;
  final String? fotoRostroUrl;
  final String? firmaUrl;
  final List<String> fotosCampo;
  final String estado;
  final int calificacion;
  final String? reporte;
  final Map<String, dynamic>? datosExtendidos;
  final bool creadaOffline;
  final String? syncId;

  Bitacora({
    this.id,
    required this.tipo,
    this.beneficiarioId,
    this.actividadId,
    this.cadenaProductivaId,
    required this.fechaInicio,
    this.fechaFin,
    this.coordInicio,
    this.coordFin,
    this.actividadesDesc = '',
    this.recomendaciones,
    this.comentariosBeneficiario,
    this.coordinacionInterinst = false,
    this.instanciaCoordinada,
    this.propositoCoordinacion,
    this.observacionesCoordinador,
    this.fotoRostroUrl,
    this.firmaUrl,
    this.fotosCampo = const [],
    this.estado = 'borrador',
    this.calificacion = 0,
    this.reporte,
    this.datosExtendidos,
    this.creadaOffline = false,
    this.syncId,
  });

  factory Bitacora.fromJson(Map<String, dynamic> json) {
    return Bitacora(
      id: json['id']?.toString(),
      tipo: json['tipo'] as String? ?? 'beneficiario',
      beneficiarioId: json['beneficiario_id']?.toString(),
      actividadId: json['actividad_id']?.toString(),
      cadenaProductivaId: json['cadena_productiva_id']?.toString(),
      fechaInicio: json['fecha_inicio'] as String? ?? DateTime.now().toIso8601String(),
      fechaFin: json['fecha_fin'] as String?,
      coordInicio: json['coord_inicio'] as String?,
      coordFin: json['coord_fin'] as String?,
      actividadesDesc: json['actividades_desc'] as String? ?? '',
      recomendaciones: json['recomendaciones'] as String?,
      comentariosBeneficiario: json['comentarios_beneficiario'] as String?,
      coordinacionInterinst: json['coordinacion_interinst'] as bool? ?? false,
      instanciaCoordinada: json['instancia_coordinada'] as String?,
      propositoCoordinacion: json['proposito_coordinacion'] as String?,
      observacionesCoordinador: json['observaciones_coordinador'] as String?,
      fotoRostroUrl: json['foto_rostro_url'] as String?,
      firmaUrl: json['firma_url'] as String?,
      fotosCampo: (json['fotos_campo'] as List<dynamic>?)?.cast<String>() ?? [],
      estado: json['estado'] as String? ?? 'borrador',
      calificacion: json['calificacion'] as int? ?? 0,
      reporte: json['reporte'] as String?,
      datosExtendidos: json['datos_extendidos'] as Map<String, dynamic>?,
      creadaOffline: json['creada_offline'] as bool? ?? false,
      syncId: json['sync_id'] as String?,
    );
  }

  Map<String, dynamic> toBody() {
    return {
      'tipo': tipo,
      if (beneficiarioId != null) 'beneficiario_id': beneficiarioId,
      if (actividadId != null) 'actividad_id': actividadId,
      if (cadenaProductivaId != null) 'cadena_productiva_id': cadenaProductivaId,
      'fecha_inicio': fechaInicio,
      if (coordInicio != null) 'coord_inicio': coordInicio,
      if (syncId != null) 'sync_id': syncId,
      'actividades_desc': actividadesDesc,
      if (recomendaciones != null) 'recomendaciones': recomendaciones,
      if (comentariosBeneficiario != null) 'comentarios_beneficiario': comentariosBeneficiario,
      'coordinacion_interinst': coordinacionInterinst,
      if (instanciaCoordinada != null) 'instancia_coordinada': instanciaCoordinada,
      if (propositoCoordinacion != null) 'proposito_coordinacion': propositoCoordinacion,
      if (observacionesCoordinador != null) 'observaciones_coordinador': observacionesCoordinador,
      if (fotoRostroUrl != null) 'foto_rostro_url': fotoRostroUrl,
      if (firmaUrl != null) 'firma_url': firmaUrl,
      if (fotosCampo.isNotEmpty) 'fotos_campo': fotosCampo,
      if (calificacion >= 1) 'calificacion': calificacion,
      if (reporte != null) 'reporte': reporte,
      if (datosExtendidos != null) 'datos_extendidos': datosExtendidos,
      'creada_offline': creadaOffline,
    };
  }

  Map<String, dynamic> toCerrarBody() {
    return {
      'fecha_fin': fechaFin ?? DateTime.now().toIso8601String(),
      if (coordFin != null) 'coord_fin': coordFin,
      'actividades_desc': actividadesDesc,
      if (recomendaciones != null) 'recomendaciones': recomendaciones,
      if (comentariosBeneficiario != null) 'comentarios_beneficiario': comentariosBeneficiario,
      'coordinacion_interinst': coordinacionInterinst,
      if (instanciaCoordinada != null) 'instancia_coordinada': instanciaCoordinada,
      if (propositoCoordinacion != null) 'proposito_coordinacion': propositoCoordinacion,
      if (calificacion >= 1) 'calificacion': calificacion,
      if (reporte != null) 'reporte': reporte,
      if (datosExtendidos != null) 'datos_extendidos': datosExtendidos,
      if (fotoRostroUrl != null) 'foto_rostro_url': fotoRostroUrl,
      if (firmaUrl != null) 'firma_url': firmaUrl,
      if (fotosCampo.isNotEmpty) 'fotos_campo': fotosCampo,
    };
  }
}
