import 'package:dio/dio.dart';
import 'api_service.dart';

class PerfilService {
  final Dio _dio = ApiService().dio;

  // Requiere PATCH /auth/me/ en el backend (por implementar)
  Future<void> updatePerfil({
    String? telefono,
    String? fotoPath,
    List<int>? oficiosIds,
  }) async {
    final fields = <String, dynamic>{};
    if (telefono != null && telefono.isNotEmpty) {
      fields['telefono'] = telefono;
    }
    if (oficiosIds != null) {
      for (var i = 0; i < oficiosIds.length; i++) {
        fields['oficios[$i]'] = oficiosIds[i];
      }
    }

    if (fotoPath != null) {
      fields['foto'] = await MultipartFile.fromFile(fotoPath);
      await _dio.patch('/auth/me/', data: FormData.fromMap(fields));
    } else if (fields.isNotEmpty) {
      await _dio.patch('/auth/me/', data: fields);
    }
  }
}
