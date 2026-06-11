import 'package:equatable/equatable.dart';

class Usuario extends Equatable {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String rol;
  final String? foto;
  final String? telefono;
  final bool verificado;
  final bool activo;

  const Usuario({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.rol,
    this.foto,
    this.telefono,
    required this.verificado,
    required this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      rol: json['rol'] as String,
      foto: json['foto'] as String?,
      telefono: json['telefono'] as String?,
      verificado: json['verificado'] as bool? ?? false,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'rol': rol,
        'foto': foto,
        'telefono': telefono,
        'verificado': verificado,
        'activo': activo,
      };

  String get nombreCompleto =>
      '${firstName.isNotEmpty ? firstName : username} $lastName'.trim();

  @override
  List<Object?> get props =>
      [id, username, email, firstName, lastName, rol, foto, telefono, verificado, activo];
}
