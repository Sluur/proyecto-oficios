import 'package:equatable/equatable.dart';

class Resena extends Equatable {
  final int id;
  final int solicitudId;
  final int autorId;
  final String? autorNombre;
  final String? autorFoto;
  final int destinatarioId;
  final int puntaje;
  final String comentario;
  final DateTime createdAt;

  const Resena({
    required this.id,
    required this.solicitudId,
    required this.autorId,
    this.autorNombre,
    this.autorFoto,
    required this.destinatarioId,
    required this.puntaje,
    required this.comentario,
    required this.createdAt,
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    int autId;
    String? autNombre;
    String? autFoto;

    final autData = json['autor'];
    if (autData is Map) {
      autId = autData['id'] as int;
      final fn = autData['first_name'] as String? ?? '';
      final ln = autData['last_name'] as String? ?? '';
      autNombre = '$fn $ln'.trim().isNotEmpty
          ? '$fn $ln'.trim()
          : autData['username'] as String? ?? '';
      autFoto = autData['foto'] as String?;
    } else {
      autId = autData as int;
    }

    return Resena(
      id: json['id'] as int,
      solicitudId: json['solicitud'] as int,
      autorId: autId,
      autorNombre: autNombre,
      autorFoto: autFoto,
      destinatarioId: json['destinatario'] as int,
      puntaje: json['puntaje'] as int,
      comentario: json['comentario'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, solicitudId, autorId, puntaje, createdAt];
}
