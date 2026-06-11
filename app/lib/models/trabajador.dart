import 'package:equatable/equatable.dart';
import 'categoria.dart';

class Trabajador extends Equatable {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? foto;
  final String? telefono;
  final bool verificado;
  final List<Categoria> oficios;
  final double? promedioPuntaje;
  final int totalResenas;
  final int totalTrabajos;
  final double? lat;
  final double? lon;

  const Trabajador({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.foto,
    this.telefono,
    required this.verificado,
    required this.oficios,
    this.promedioPuntaje,
    required this.totalResenas,
    required this.totalTrabajos,
    this.lat,
    this.lon,
  });

  String get nombreCompleto {
    final n = '$firstName $lastName'.trim();
    return n.isNotEmpty ? n : username;
  }

  Categoria? get oficiosPrincipal => oficios.isNotEmpty ? oficios.first : null;

  factory Trabajador.fromJson(Map<String, dynamic> json) {
    double? lat, lon;
    final ubic = json['ubicacion'];
    if (ubic is Map) {
      lat = (ubic['lat'] as num?)?.toDouble();
      lon = (ubic['lon'] as num?)?.toDouble();
    }
    final raw = json['oficios'] as List? ?? [];
    return Trabajador(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      foto: json['foto'] as String?,
      telefono: json['telefono'] as String?,
      verificado: json['verificado'] as bool? ?? false,
      oficios: raw
          .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
          .toList(),
      promedioPuntaje: (json['promedio_puntaje'] as num?)?.toDouble(),
      totalResenas: json['total_resenas'] as int? ?? 0,
      totalTrabajos: json['total_trabajos'] as int? ?? 0,
      lat: lat,
      lon: lon,
    );
  }

  @override
  List<Object?> get props =>
      [id, username, verificado, totalResenas, totalTrabajos];
}
