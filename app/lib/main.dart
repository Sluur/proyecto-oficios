import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shared/main_navigation.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

/// Permite que las pantallas dentro de [MainNavigation] se enteren cuando
/// vuelve a mostrarse la ruta (por ejemplo, al volver de crear una
/// solicitud) y así puedan refrescar sus datos.
final routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    BlocProvider(
      create: (_) => AuthBloc(authService: AuthService())
        ..add(const CheckAuthStatus()),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chamba',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorObservers: [routeObserver],
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is Authenticated) {
            return MainNavigation(usuario: state.usuario);
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/home': (context) {
          final state = context.read<AuthBloc>().state;
          if (state is Authenticated) {
            return MainNavigation(usuario: state.usuario);
          }
          return const LoginScreen();
        },
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
