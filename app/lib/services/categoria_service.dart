import 'package:dio/dio.dart';
import '../models/categoria.dart';
import 'api_service.dart';

class CategoriaService {
  final Dio _dio = ApiService().dio;

  Future<List<Categoria>> getCategorias() async {
    final response = await _dio.get('/categorias/');
    final data = response.data;
    final List<dynamic> lista = data is List ? data : (data['results'] as List? ?? []);
    return lista
        .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
