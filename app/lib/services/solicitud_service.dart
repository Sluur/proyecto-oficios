import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/solicitud.dart';
import 'api_service.dart';

class SolicitudService {
  final Dio _dio = ApiService().dio;

  Future<List<Solicitud>> getSolicitudes({
    double? lat,
    double? lon,
    double? radio,
    int? categoriaId,
    String? estado,
  }) async {
    final params = <String, dynamic>{};
    if (lat != null) params['lat'] = lat;
    if (lon != null) params['lon'] = lon;
    if (radio != null) params['radio'] = radio;
    if (categoriaId != null) params['categoria'] = categoriaId;
    if (estado != null) params['estado'] = estado;

    final response = await _dio.get('/solicitudes/', queryParameters: params);
    final data = response.data;
    final List<dynamic> lista = data is List ? data : (data['results'] as List? ?? []);
    return lista
        .map((e) => Solicitud.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Solicitud>> getMisSolicitudes() async {
    try {
      final response = await _dio.get('/solicitudes/mis/');
      debugPrint(
          'GET /solicitudes/mis/ -> ${response.statusCode}: ${response.data}');
      final data = response.data;
      final List<dynamic> lista =
          data is List ? data : (data['results'] as List? ?? []);
      return lista
          .map((e) => Solicitud.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error en GET /solicitudes/mis/: $e');
      rethrow;
    }
  }

  Future<Solicitud> getSolicitud(int id) async {
    final response = await _dio.get('/solicitudes/$id/');
    return Solicitud.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Solicitud> createSolicitud({
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required double latitud,
    required double longitud,
    XFile? foto,
  }) async {
    final fields = <String, dynamic>{
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoriaId,
      'lat': latitud,
      'lon': longitud,
    };
    if (foto != null) {
      final bytes = await foto.readAsBytes();
      fields['foto'] = MultipartFile.fromBytes(bytes, filename: 'foto.jpg');
    }
    final response = await _dio.post('/solicitudes/', data: FormData.fromMap(fields));
    return Solicitud.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cerrarSolicitud(int id) async {
    await _dio.post('/solicitudes/$id/cerrar/');
  }
}
