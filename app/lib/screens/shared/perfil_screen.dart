import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/usuario.dart';
import '../../theme/app_theme.dart';
import '../cliente/editar_perfil_cliente_screen.dart';
import '../trabajador/editar_perfil_trabajador_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  void _editarPerfil(BuildContext context, Usuario usuario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => usuario.rol == 'trabajador'
            ? EditarPerfilTrabajadorScreen(usuario: usuario)
            : EditarPerfilClienteScreen(usuario: usuario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final usuario = state is Authenticated ? state.usuario : null;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  CircleAvatar(
                    radius: 52,
                    backgroundColor:
                        AppTheme.primary.withValues(alpha: 0.12),
                    backgroundImage: (usuario.foto != null &&
                            usuario.foto!.isNotEmpty)
                        ? NetworkImage(usuario.foto!)
                        : null,
                    child: (usuario.foto == null || usuario.foto!.isEmpty)
                        ? Text(
                            usuario.nombreCompleto.isNotEmpty
                                ? usuario.nombreCompleto[0].toUpperCase()
                                : '?',
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    usuario.nombreCompleto,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textTitle,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  Text(
                    usuario.email,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textSubtitle),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      usuario.rol == 'trabajador' ? 'Trabajador' : 'Cliente',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (usuario.rol == 'trabajador' &&
                      usuario.bio != null &&
                      usuario.bio!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        usuario.bio!,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.textTitle),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (usuario.telefono != null &&
                      usuario.telefono!.isNotEmpty) ...[
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      text: usuario.telefono!,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (usuario.verificado) ...[
                    _InfoRow(
                      icon: Icons.verified_outlined,
                      text: 'Perfil verificado',
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _editarPerfil(context, usuario),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar perfil'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.primary),
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () {
                        context
                            .read<AuthBloc>()
                            .add(const LogoutRequested());
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
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.color = AppTheme.textSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}
