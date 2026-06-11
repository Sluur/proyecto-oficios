import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined,
                size: 64,
                color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text(
              'Todavía no enviaste propuestas',
              style: TextStyle(color: AppTheme.textSubtitle),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _propuestas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PropuestaCard(propuesta: _propuestas[i]),
    );
  }
}

class _PropuestaCard extends StatelessWidget {
  final Propuesta propuesta;
  const _PropuestaCard({required this.propuesta});

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

            // Contactar si fue aceptada
            if (propuesta.estado == 'aceptada' &&
                propuesta.clienteTelefono != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 16, color: AppTheme.successColor),
                  const SizedBox(width: 6),
                  Text(
                    propuesta.clienteTelefono!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'tel:${propuesta.clienteTelefono}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: const Text('Contactar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
