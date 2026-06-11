import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final usuario = state is Authenticated ? state.usuario : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                usuario?.nombreCompleto.isNotEmpty == true
                    ? usuario!.nombreCompleto[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              usuario?.nombreCompleto ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '@${usuario?.username ?? ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                usuario?.rol == 'trabajador' ? 'Trabajador' : 'Cliente',
              ),
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
