import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../main.dart';
import '../../models/categoria.dart';
import '../../models/solicitud.dart';
import '../../models/usuario.dart';
import '../../services/solicitud_service.dart';
import '../../services/trabajador_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';
import '../../utils/time_ago.dart';
import '../../widgets/categoria_card.dart';
import '../shared/detalle_solicitud_screen.dart';

class ExplorarScreen extends StatefulWidget {
  final Usuario usuario;
  const ExplorarScreen({super.key, required this.usuario});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> with RouteAware {
  double? _lat;
  double? _lon;
  List<Categoria> _misCategorias = [];
  List<Solicitud> _todasSolicitudes = [];
  List<Solicitud> _solicitudes = [];
  int? _filtroCategoria;
  String _orden = 'distancia';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
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
    _loadSolicitudes();
  }

  Future<void> _init() async {
    if (mounted) setState(() => _loading = true);
    final ubicacion = await LocationHelper.getUbicacionGuardada();
    _lat = ubicacion.lat;
    _lon = ubicacion.lon;
    await _loadMisCategorias();
    await _loadSolicitudes();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMisCategorias() async {
    try {
      final t = await TrabajadorService().getTrabajador(widget.usuario.id);
      if (mounted) setState(() => _misCategorias = t.oficios);
    } catch (_) {}
  }

  Future<void> _loadSolicitudes() async {
    try {
      final list =
          await SolicitudService().getSolicitudes(estado: 'abierta');
      if (mounted) {
        setState(() {
          _todasSolicitudes = list;
          _solicitudes = _sorted(_filtered(list));
        });
      }
    } catch (e) {
      debugPrint('Error al cargar solicitudes: $e');
    }
  }

  List<Solicitud> _filtered(List<Solicitud> list) {
    if (_filtroCategoria != null) {
      return list.where((s) => s.categoriaId == _filtroCategoria).toList();
    }
    if (_misCategorias.isNotEmpty) {
      final ids = _misCategorias.map((c) => c.id).toSet();
      return list.where((s) => ids.contains(s.categoriaId)).toList();
    }
    return list;
  }

  List<Solicitud> _sorted(List<Solicitud> list) {
    final sorted = List<Solicitud>.from(list);
    if (_orden == 'distancia' && _lat != null && _lon != null) {
      sorted.sort((a, b) {
        final da = _dist(a);
        final db = _dist(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    } else {
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  double? _dist(Solicitud s) {
    if (_lat == null || _lon == null || s.latitud == null || s.longitud == null) {
      return null;
    }
    return Geolocator.distanceBetween(_lat!, _lon!, s.latitud!, s.longitud!) /
        1000;
  }

  void _aplicarFiltro() {
    setState(() => _solicitudes = _sorted(_filtered(_todasSolicitudes)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar solicitudes'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            initialValue: _orden,
            onSelected: (v) {
              setState(() {
                _orden = v;
                _solicitudes = _sorted(_solicitudes);
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reciente', child: Text('Más recientes')),
              PopupMenuItem(value: 'distancia', child: Text('Más cercanos')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            // Filtros por categoría
            if (_misCategorias.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Todos',
                        selected: _filtroCategoria == null,
                        onTap: () {
                          _filtroCategoria = null;
                          _aplicarFiltro();
                        },
                      ),
                      ..._misCategorias.map((cat) => _FilterChip(
                            label: cat.nombre,
                            icon: iconoParaCategoria(cat.icono),
                            selected: _filtroCategoria == cat.id,
                            onTap: () {
                              _filtroCategoria = cat.id;
                              _aplicarFiltro();
                            },
                          )),
                    ],
                  ),
                ),
              ),

            // Lista
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_solicitudes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_outlined,
                          size: 64,
                          color: AppTheme.textSubtitle.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        _todasSolicitudes.isEmpty
                            ? 'No hay solicitudes abiertas por el momento'
                            : 'No hay solicitudes abiertas en tus categorías por ahora',
                        style: textTheme.bodyLarge
                            ?.copyWith(color: AppTheme.textSubtitle),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemCount: _solicitudes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _SolicitudFeedCard(
                    solicitud: _solicitudes[i],
                    distanciaKm: _dist(_solicitudes[i]),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleSolicitudScreen(
                          solicitud: _solicitudes[i],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Componentes privados ─────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14,
                    color: selected ? Colors.white : AppTheme.textSubtitle),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolicitudFeedCard extends StatelessWidget {
  final Solicitud solicitud;
  final double? distanciaKm;
  final VoidCallback onTap;

  const _SolicitudFeedCard({
    required this.solicitud,
    required this.onTap,
    this.distanciaKm,
  });

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría
                    Row(
                      children: [
                        if (solicitud.categoriaNombre != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              solicitud.categoriaNombre!,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Título
                    Text(
                      solicitud.titulo,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textTitle,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (solicitud.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        solicitud.descripcion,
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppTheme.textSubtitle),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Meta
                    Wrap(
                      spacing: 10,
                      children: [
                        if (distanciaKm != null)
                          _MetaChip(
                            icon: Icons.location_on_outlined,
                            label: 'a ${distanciaKm!.toStringAsFixed(1)} km',
                          ),
                        _MetaChip(
                          icon: Icons.access_time,
                          label: timeAgo(solicitud.createdAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (solicitud.foto != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    solicitud.foto!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSubtitle),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSubtitle,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
