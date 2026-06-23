import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/usuario.dart';
import 'api_service.dart';

class PerfilService {
  final Dio _dio = ApiService().dio;

  Future<Usuario> updatePerfil({
    String? firstName,
    String? lastName,
    String? telefono,
    String? bio,
    List<int>? oficiosIds,
  }) async {
    final fields = <String, dynamic>{};
    if (firstName != null) fields['first_name'] = firstName;
    if (lastName != null) fields['last_name'] = lastName;
    if (telefono != null) fields['telefono'] = telefono;
    if (bio != null) fields['bio'] = bio;
    if (oficiosIds != null) fields['oficios_ids'] = oficiosIds;
    final response = await _dio.patch('/auth/me/', data: fields);
    return Usuario.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Usuario> updateFoto(XFile foto) async {
    final bytes = await foto.readAsBytes();
    final formData = FormData.fromMap({
      'foto': MultipartFile.fromBytes(bytes, filename: 'foto.jpg'),
    });
    final response = await _dio.patch('/auth/me/', data: formData);
    return Usuario.fromJson(response.data as Map<String, dynamic>);
  }
}
