import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/usuario.dart';
import '../../services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<UserUpdated>(_onUserUpdated);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final loggedIn = await _authService.isLoggedIn();
      if (loggedIn) {
        final usuario = await _authService.getMe();
        emit(Authenticated(usuario));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.login(email: event.email, password: event.password);
      final usuario = await _authService.getMe();
      emit(Authenticated(usuario));
    } catch (e) {
      emit(AuthError(_errorMessage(e)));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.register(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        telefono: event.telefono,
        rol: event.rol,
      );
      final usuario = await _authService.getMe();
      emit(Authenticated(usuario));
    } catch (e) {
      emit(AuthError(_errorMessage(e)));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    emit(const Unauthenticated());
  }

  void _onUserUpdated(UserUpdated event, Emitter<AuthState> emit) {
    emit(Authenticated(event.usuario));
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Sin conexión al servidor. Verificá tu red';
      }

      if (data is Map) {
        // SimpleJWT y DRF usan 'detail' para errores de un solo mensaje
        if (data.containsKey('detail')) {
          final detail = data['detail'].toString();
          if (status == 401 || detail.toLowerCase().contains('credentials') || detail.toLowerCase().contains('account')) {
            return 'Usuario o contraseña incorrectos';
          }
          return detail;
        }

        // Errores campo por campo de DRF
        final messages = <String>[];
        data.forEach((key, value) {
          final label = _fieldLabel(key.toString());
          final prefix = label.isNotEmpty ? '$label: ' : '';
          if (value is List) {
            for (final msg in value) {
              messages.add('$prefix$msg');
            }
          } else if (value is String) {
            messages.add('$prefix$value');
          }
        });
        if (messages.isNotEmpty) return messages.join('\n');
      }

      if (status == 401) return 'Usuario o contraseña incorrectos';
      if (status == 400) return 'Revisá los datos ingresados';
      if (status != null && status >= 500) return 'Error en el servidor. Intentá más tarde';
    }
    return 'Ocurrió un error. Intentá de nuevo';
  }

  String _fieldLabel(String key) {
    const labels = {
      'username': 'Usuario',
      'email': 'Email',
      'password': 'Contraseña',
      'rol': 'Rol',
      'first_name': 'Nombre',
      'last_name': 'Apellido',
      'telefono': 'Teléfono',
      'non_field_errors': '',
    };
    return labels[key] ?? key;
  }
}
