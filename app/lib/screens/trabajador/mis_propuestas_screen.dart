import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/propuesta.dart';
import '../../services/propuesta_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';

class MisPropuestasScreen extends StatefulWidget {
  const MisPropuestasScreen({super.key});

  @override
  State<MisPropuestasScreen> createState() => _MisPropuestasScreenState();
}

class _MisPropuestasScreenState extends State<MisPropuestasScreen> {
  List<Propuesta> _propuestas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await PropuestaService().getMisPropuestas();
      if (mounted) {
        setState(() {
          _propuestas = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar tus propuestas';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis propuestas')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: const TextStyle(color: AppTheme.textSubtitle)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_propuestas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.send_outlined,
                  size: 64, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text(
                'No enviaste propuestas todavía',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSubtitle, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  DefaultTabController.maybeOf(context)?.animateTo(0);
                },
                icon: const Icon(Icons.search),
                label: const Text('Explorar solicitudes'),
              ),
            ],
          ),
        ),
      );
    }

    final authState = context.read<AuthBloc>().state;
    final workerNombre = authState is Authenticated
        ? authState.usuario.nombreCompleto
        : 'Trabajador';

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _propuestas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PropuestaCard(
        propuesta: _propuestas[i],
        workerNombre: workerNombre,
      ),
    );
  }
}

class _PropuestaCard extends StatelessWidget {
  final Propuesta propuesta;
  final String workerNombre;

  const _PropuestaCard({
    required this.propuesta,
    required this.workerNombre,
  });

  Color get _colorEstado {
    switch (propuesta.estado) {
      case 'aceptada':
        return AppTheme.successColor;
      case 'rechazada':
        return AppTheme.textSubtitle;
      default:
        return AppTheme.accent;
    }
  }

  String get _labelEstado {
    switch (propuesta.estado) {
      case 'aceptada':
        return 'Aceptada';
      case 'rechazada':
        return 'Rechazada';
      default:
        return 'Pendiente';
    }
  }

  String? _waUrl() {
    final tel = propuesta.clienteTelefono;
    if (tel == null || tel.isEmpty) return null;
    var num = tel.replaceAll(RegExp(r'[^\d]'), '');
    if (num.isEmpty) return null;
    if (!num.startsWith('549')) {
      if (num.startsWith('54')) {
        num = '549${num.substring(2)}';
      } else {
        if (num.startsWith('0')) num = num.substring(1);
        num = '549$num';
      }
    }
    final titulo = propuesta.solicitudTitulo ?? 'tu solicitud';
    final msg = 'Hola, soy $workerNombre de Chamba. '
        'Aceptaste mi propuesta para: $titulo. ¿Cuándo coordinamos?';
    return 'https://wa.me/$num?text=${Uri.encodeComponent(msg)}';
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: título + estado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    propuesta.solicitudTitulo ??
                        'Solicitud #${propuesta.solicitudId}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textTitle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _colorEstado.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _labelEstado,
                    style: textTheme.labelSmall?.copyWith(
                      color: _colorEstado,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Precio y fecha
            Row(
              children: [
                const Icon(Icons.attach_money,
                    size: 16, color: AppTheme.textSubtitle),
                Text(
                  '\$${propuesta.precioEstimado.toStringAsFixed(0)}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textTitle,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time,
                    size: 14, color: AppTheme.textSubtitle),
                const SizedBox(width: 3),
                Text(
                  timeAgo(propuesta.createdAt),
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppTheme.textSubtitle),
                ),
              ],
            ),

            if (propuesta.mensaje.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                propuesta.mensaje,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppTheme.textSubtitle),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Sección inferior para propuestas aceptadas
            if (propuesta.estado == 'aceptada') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              if (propuesta.solicitudEstado == 'en_progreso' &&
                  propuesta.clienteTelefono != null) ...[
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppTheme.textSubtitle),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        propuesta.clienteTelefono!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppTheme.textSubtitle),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _launch('tel:${propuesta.clienteTelefono}'),
                        icon: const Icon(Icons.phone, size: 15),
                        label: const Text('Llamar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.successColor,
                          side:
                              const BorderSide(color: AppTheme.successColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final url = _waUrl();
                          if (url != null) _launch(url);
                        },
                        icon: const Icon(Icons.chat, size: 15),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (propuesta.solicitudEstado == 'cerrada') ...[
                _StatusBadge(
                  icon: Icons.check_circle_outline,
                  label: 'Trabajo completado',
                  color: AppTheme.textSubtitle,
                ),
              ] else if (propuesta.solicitudEstado == 'cancelada') ...[
                _StatusBadge(
                  icon: Icons.cancel_outlined,
                  label: 'Cancelada',
                  color: AppTheme.errorColor,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
