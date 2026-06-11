import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';
import 'api_service.dart';

class AuthService {
  final Dio _dio = ApiService().dio;

  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    final response = await _dio.post('/auth/register/', data: {
      'username': _usernameFromEmail(email),
      'email': email,
      'password': password,
      'nombre': nombre,
      'rol': rol,
    });
    // El endpoint de registro ya devuelve access + refresh directamente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, response.data['access'] as String);
    await prefs.setString(ApiConfig.refreshKey, response.data['refresh'] as String);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/token/', data: {
      'email': email,
      'password': password,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, response.data['access'] as String);
    await prefs.setString(ApiConfig.refreshKey, response.data['refresh'] as String);
  }

  Future<Usuario> getMe() async {
    final response = await _dio.get('/auth/me/');
    return Usuario.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove(ApiConfig.refreshKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static String _usernameFromEmail(String email) {
    final local = email.split('@').first;
    return local.replaceAll(RegExp(r'[^\w]'), '_').toLowerCase();
  }
}
