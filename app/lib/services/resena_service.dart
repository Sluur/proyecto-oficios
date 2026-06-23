import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/resena.dart';
import 'api_service.dart';

class ResenaService {
  final Dio _dio = ApiService().dio;

  Future<List<Resena>> getResenasPorUsuario(int usuarioId) async {
    try {
      final response = await _dio.get('/usuarios/$usuarioId/resenas/');
      final data = response.data;
      final List lista =
          data is List ? data : (data['results'] as List? ?? []);
      return lista
          .map((e) => Resena.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error en GET /usuarios/$usuarioId/resenas/: $e');
      rethrow;
    }
  }

  Future<Resena> crearResena({
    required int solicitudId,
    required int puntaje,
    required String comentario,
  }) async {
    try {
      final response = await _dio.post(
        '/solicitudes/$solicitudId/resenas/',
        data: {
          'puntaje': puntaje,
          'comentario': comentario,
        },
      );
      debugPrint(
          'POST /solicitudes/$solicitudId/resenas/ -> ${response.statusCode}: ${response.data}');
      return Resena.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error en POST /solicitudes/$solicitudId/resenas/: $e');
      rethrow;
    }
  }
}
