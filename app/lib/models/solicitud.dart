import 'package:equatable/equatable.dart';

class Solicitud extends Equatable {
  final int id;
  final String titulo;
  final String descripcion;
  final String? foto;
  final double? latitud;
  final double? longitud;
  final String estado;
  final int clienteId;
  final String? clienteNombre;
  final String? clienteTelefono;
  final int? trabajadorAceptadoId;
  final String? trabajadorAceptadoNombre;
  final String? trabajadorAceptadoTelefono;
  final int categoriaId;
  final String? categoriaNombre;
  final DateTime createdAt;
  final DateTime? closedAt;

  const Solicitud({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.foto,
    this.latitud,
    this.longitud,
    required this.estado,
    required this.clienteId,
    this.clienteNombre,
    this.clienteTelefono,
    this.trabajadorAceptadoId,
    this.trabajadorAceptadoNombre,
    this.trabajadorAceptadoTelefono,
    required this.categoriaId,
    this.categoriaNombre,
    required this.createdAt,
    this.closedAt,
  });

  static String? _nombreDe(Map data) {
    final fn = data['first_name'] as String? ?? '';
    final ln = data['last_name'] as String? ?? '';
    final un = data['username'] as String? ?? '';
    final nombre = '$fn $ln'.trim();
    return nombre.isNotEmpty ? nombre : (un.isNotEmpty ? un : null);
  }

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lon;
    final ubicacion = json['ubicacion'];
    if (ubicacion != null && ubicacion is Map) {
      if (ubicacion.containsKey('lat') && ubicacion.containsKey('lon')) {
        lat = (ubicacion['lat'] as num?)?.toDouble();
        lon = (ubicacion['lon'] as num?)?.toDouble();
      } else {
        final coords = ubicacion['coordinates'] as List?;
        if (coords != null && coords.length >= 2) {
          lon = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }
    }

    final categoriaData = json['categoria'];
    int catId;
    String? catNombre;
    if (categoriaData is Map) {
      catId = categoriaData['id'] as int;
      catNombre = categoriaData['nombre'] as String?;
    } else {
      catId = categoriaData as int;
    }

    final clienteData = json['cliente'];
    int clienteId;
    String? clienteNombre;
    String? clienteTelefono;
    if (clienteData is Map) {
      clienteId = clienteData['id'] as int;
      clienteNombre = _nombreDe(clienteData);
      clienteTelefono = clienteData['telefono'] as String?;
    } else {
      clienteId = clienteData as int;
    }

    final trabajadorData = json['trabajador_aceptado'];
    int? trabajadorId;
    String? trabajadorNombre;
    String? trabajadorTelefono;
    if (trabajadorData is Map) {
      trabajadorId = trabajadorData['id'] as int;
      trabajadorNombre = _nombreDe(trabajadorData);
      trabajadorTelefono = trabajadorData['telefono'] as String?;
    } else {
      trabajadorId = trabajadorData as int?;
    }

    return Solicitud(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      foto: json['foto'] as String?,
      latitud: lat,
      longitud: lon,
      estado: json['estado'] as String,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      trabajadorAceptadoId: trabajadorId,
      trabajadorAceptadoNombre: trabajadorNombre,
      trabajadorAceptadoTelefono: trabajadorTelefono,
      categoriaId: catId,
      categoriaNombre: catNombre,
      createdAt: DateTime.parse(json['created_at'] as String),
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
    );
  }

  bool get estaActiva => estado == 'abierta' || estado == 'en_progreso';

  @override
  List<Object?> get props => [id, titulo, estado, clienteId, categoriaId, createdAt];
}
