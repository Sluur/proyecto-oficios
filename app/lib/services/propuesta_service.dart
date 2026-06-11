import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/propuesta.dart';
import 'api_service.dart';

class PropuestaService {
  final Dio _dio = ApiService().dio;

  Future<List<Propuesta>> getMisPropuestas() async {
    try {
      final response = await _dio.get('/propuestas/mis/');
      debugPrint(
          'GET /propuestas/mis/ -> ${response.statusCode}: ${response.data}');
      final data = response.data;
      final List lista =
          data is List ? data : (data['results'] as List? ?? []);
      return lista
          .map((e) => Propuesta.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error en GET /propuestas/mis/: $e');
      rethrow;
    }
  }

  Future<Propuesta> enviarPropuesta({
    required int solicitudId,
    required double precio,
    required String mensaje,
  }) async {
    final response = await _dio.post(
      '/solicitudes/$solicitudId/propuestas/',
      data: {
        'precio_estimado': precio,
        'mensaje': mensaje,
      },
    );
    return Propuesta.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Propuesta>> getPropuestasDeSolicitud(int solicitudId) async {
    final response = await _dio.get('/solicitudes/$solicitudId/propuestas/');
    final data = response.data;
    final List lista = data is List ? data : (data['results'] as List? ?? []);
    return lista
        .map((e) => Propuesta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Propuesta> aceptarPropuesta(int propuestaId) async {
    final response = await _dio.post('/propuestas/$propuestaId/aceptar/');
    return Propuesta.fromJson(response.data as Map<String, dynamic>);
  }
}
