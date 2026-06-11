import 'package:equatable/equatable.dart';

class Categoria extends Equatable {
  final int id;
  final String nombre;
  final String icono;
  final String descripcion;
  final bool activa;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.descripcion,
    required this.activa,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      icono: json['icono'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      activa: json['activa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'icono': icono,
        'descripcion': descripcion,
        'activa': activa,
      };

  @override
  List<Object?> get props => [id, nombre, icono, descripcion, activa];
}
