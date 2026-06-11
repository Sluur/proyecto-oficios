import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/categoria.dart';
import '../../models/trabajador.dart';
import '../../services/trabajador_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';
import '../../widgets/trabajador_card.dart';
import '../shared/perfil_trabajador_screen.dart';
import 'create_solicitud_screen.dart';

class TrabajadoresCategoriaScreen extends StatefulWidget {
  final Categoria categoria;
  const TrabajadoresCategoriaScreen({super.key, required this.categoria});

  @override
  State<TrabajadoresCategoriaScreen> createState() =>
      _TrabajadoresCategoriaScreenState();
}

class _TrabajadoresCategoriaScreenState
    extends State<TrabajadoresCategoriaScreen> {
  double? _lat;
  double? _lon;
  List<Trabajador> _trabajadores = [];
  bool _loading = true;
  bool _mostrandoTodos = false;
  String _orden = 'calificacion';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (mounted) setState(() => _loading = true);
    final ubicacion = await LocationHelper.getUbicacionGuardada();
    _lat = ubicacion.lat;
    _lon = ubicacion.lon;
    await _loadTrabajadores();
  }

  Future<void> _loadTrabajadores() async {
    try {
      var list = await TrabajadorService().getTrabajadores(
        lat: _lat,
        lon: _lon,
        radio: 50,
        oficioId: widget.categoria.id,
      );
      var mostrandoTodos = false;

      if (list.isEmpty) {
        list = await TrabajadorService().getTrabajadores(
          oficioId: widget.categoria.id,
        );
        mostrandoTodos = list.isNotEmpty;
      }

      if (mounted) {
        setState(() {
          _trabajadores = _sorted(list);
          _mostrandoTodos = mostrandoTodos;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar trabajadores: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Trabajador> _sorted(List<Trabajador> list) {
    final sorted = List<Trabajador>.from(list);
    if (_orden == 'calificacion') {
      sorted.sort((a, b) =>
          (b.promedioPuntaje ?? 0).compareTo(a.promedioPuntaje ?? 0));
    } else {
      sorted.sort((a, b) => _dist(a).compareTo(_dist(b)));
    }
    return sorted;
  }

  double _dist(Trabajador t) {
    if (_lat == null || _lon == null || t.lat == null || t.lon == null) {
      return 999;
    }
    return Geolocator.distanceBetween(_lat!, _lon!, t.lat!, t.lon!) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoria.nombre),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            initialValue: _orden,
            onSelected: (v) => setState(() {
              _orden = v;
              _trabajadores = _sorted(_trabajadores);
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'calificacion',
                  child: Text('Mejor calificados')),
              PopupMenuItem(
                  value: 'distancia', child: Text('Más cercanos')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        color: AppTheme.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _trabajadores.isEmpty
                ? _EmptyState(categoria: widget.categoria)
                : Column(
                    children: [
                      if (_mostrandoTodos)
                        Container(
                          width: double.infinity,
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Text(
                            'Mostrando trabajadores de toda la plataforma',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _trabajadores.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final t = _trabajadores[i];
                            final km = t.lat != null ? _dist(t) : null;
                            return TrabajadorCard(
                              trabajador: t,
                              distanciaKm: km,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PerfilTrabajadorScreen(
                                      trabajadorId: t.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateSolicitudScreen(
                  categoriaPreseleccionada: widget.categoria,
                ),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: Text('Publicar solicitud de ${widget.categoria.nombre}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Categoria categoria;
  const _EmptyState({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 64,
              color: AppTheme.textSubtitle.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay trabajadores de ${categoria.nombre} en tu zona todavía',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.textSubtitle),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
