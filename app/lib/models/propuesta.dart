import 'package:equatable/equatable.dart';

class Propuesta extends Equatable {
  final int id;
  final int solicitudId;
  final String? solicitudTitulo;
  final String? solicitudEstado;
  final String? clienteTelefono;
  final int trabajadorId;
  final String trabajadorNombre;
  final String? trabajadorFoto;
  final String? trabajadorTelefono;
  final bool trabajadorVerificado;
  final double precioEstimado;
  final String mensaje;
  final String estado;
  final DateTime createdAt;

  const Propuesta({
    required this.id,
    required this.solicitudId,
    this.solicitudTitulo,
    this.solicitudEstado,
    this.clienteTelefono,
    required this.trabajadorId,
    required this.trabajadorNombre,
    this.trabajadorFoto,
    this.trabajadorTelefono,
    required this.trabajadorVerificado,
    required this.precioEstimado,
    required this.mensaje,
    required this.estado,
    required this.createdAt,
  });

  factory Propuesta.fromJson(Map<String, dynamic> json) {
    final solData = json['solicitud'];
    final solId = solData is Map ? solData['id'] as int : solData as int;

    int trabId;
    String trabNombre;
    String? trabFoto;
    String? trabTelefono;
    bool trabVerificado = false;

    final trabData = json['trabajador'];
    if (trabData is Map) {
      trabId = trabData['id'] as int;
      final fn = trabData['first_name'] as String? ?? '';
      final ln = trabData['last_name'] as String? ?? '';
      final un = trabData['username'] as String? ?? '';
      final nombre = '$fn $ln'.trim();
      trabNombre = nombre.isNotEmpty ? nombre : un;
      trabFoto = trabData['foto'] as String?;
      trabTelefono = trabData['telefono'] as String?;
      trabVerificado = trabData['verificado'] as bool? ?? false;
    } else {
      trabId = trabData as int;
      trabNombre = '';
    }

    return Propuesta(
      id: json['id'] as int,
      solicitudId: solId,
      solicitudTitulo: json['solicitud_titulo'] as String?,
      solicitudEstado: json['solicitud_estado'] as String?,
      clienteTelefono: json['solicitud_cliente_telefono'] as String?,
      trabajadorId: trabId,
      trabajadorNombre: trabNombre,
      trabajadorFoto: trabFoto,
      trabajadorTelefono: trabTelefono,
      trabajadorVerificado: trabVerificado,
      precioEstimado: double.parse(json['precio_estimado'].toString()),
      mensaje: json['mensaje'] as String? ?? '',
      estado: json['estado'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'solicitud': solicitudId,
        'trabajador': trabajadorId,
        'precio_estimado': precioEstimado,
        'mensaje': mensaje,
        'estado': estado,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, solicitudId, estado, createdAt];
}
