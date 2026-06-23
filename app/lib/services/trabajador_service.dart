import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/trabajador.dart';
import 'api_service.dart';

class TrabajadorService {
  final Dio _dio = ApiService().dio;

  Future<List<Trabajador>> getTrabajadores({
    double? lat,
    double? lon,
    double? radio,
    int? oficioId,
  }) async {
    final params = <String, dynamic>{};
    if (lat != null) params['lat'] = lat;
    if (lon != null) params['lon'] = lon;
    if (radio != null) params['radio'] = radio;
    if (oficioId != null) params['oficio'] = oficioId;

    final response =
        await _dio.get('/trabajadores/', queryParameters: params);
    final data = response.data;
    final List lista = data is List ? data : (data['results'] as List? ?? []);
    return lista
        .map((e) => Trabajador.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Trabajador> getTrabajador(int id) async {
    try {
      final response = await _dio.get('/trabajadores/$id/');
      debugPrint(
          'GET /trabajadores/$id/ -> ${response.statusCode}: ${response.data}');
      return Trabajador.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error en GET /trabajadores/$id/: $e');
      rethrow;
    }
  }
}
