/// Utilidades de conversión usadas por los mappers de la capa de datos.
Map<String, dynamic> mapa(dynamic v) => Map<String, dynamic>.from(v as Map);

List<Map<String, dynamic>> listaDeMapas(dynamic v) =>
    (v as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

List<String> textos(dynamic v) => (v as List? ?? const []).map((e) => e.toString()).toList();

DateTime fecha(dynamic v) => DateTime.parse(v as String).toLocal();

DateTime? fechaOpcional(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();

double numero(dynamic v) => v == null ? 0 : (v as num).toDouble();

String? textoOpcional(dynamic v) => v?.toString();
