import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/solicitud.dart';
import '../../services/solicitud_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../widgets/categoria_card.dart';
import '../shared/detalle_solicitud_screen.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen>
    with RouteAware {
  List<Solicitud> _solicitudes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SolicitudService().getMisSolicitudes();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _solicitudes = list;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar mis solicitudes: $e');
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar tus solicitudes';
          _loading = false;
        });
      }
    }
  }

  Future<void> _abrirDetalle(Solicitud solicitud) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleSolicitudScreen(solicitud: solicitud),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Solicitudes')),
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
    if (_solicitudes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.list_alt_outlined, size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            'Tus solicitudes aparecerán acá',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSubtitle),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _solicitudes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _SolicitudListTile(
        solicitud: _solicitudes[i],
        onTap: () => _abrirDetalle(_solicitudes[i]),
      ),
    );
  }
}

class _SolicitudListTile extends StatelessWidget {
  final Solicitud solicitud;
  final VoidCallback onTap;

  const _SolicitudListTile({required this.solicitud, required this.onTap});

  Color get _colorEstado {
    switch (solicitud.estado) {
      case 'abierta':
        return AppTheme.successColor;
      case 'en_progreso':
        return AppTheme.secondary;
      case 'cerrada':
        return AppTheme.textSubtitle;
      default:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconoParaCategoria(solicitud.categoriaNombre ?? ''),
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      solicitud.titulo,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (solicitud.categoriaNombre != null) ...[
                          Text(
                            solicitud.categoriaNombre!,
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSubtitle),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          timeAgo(solicitud.createdAt),
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSubtitle),
                        ),
                      ],
                    ),
                  ],
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
                  solicitud.estado.replaceAll('_', ' ').toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: _colorEstado,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
