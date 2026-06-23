import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/solicitud.dart';
import '../../models/usuario.dart';
import '../../services/categoria_service.dart';
import '../../services/solicitud_service.dart';
import '../../models/categoria.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';
import '../../widgets/categoria_card.dart';
import '../shared/detalle_solicitud_screen.dart';
import '../shared/seleccionar_ubicacion_screen.dart';
import 'create_solicitud_screen.dart';
import 'todas_categorias_screen.dart';
import 'trabajadores_categoria_screen.dart';

class HomeScreen extends StatefulWidget {
  final Usuario usuario;
  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  UbicacionGuardada? _ubicacion;
  List<Categoria> _categorias = [];
  List<Solicitud> _solicitudesActivas = [];
  bool _loadingCategorias = true;
  String? _errorCategorias;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadSolicitudesActivas();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUbicacion(),
      _loadCategorias(),
      _loadSolicitudesActivas(),
    ]);
  }

  Future<void> _loadUbicacion() async {
    final ubicacion = await LocationHelper.getUbicacionGuardada();
    if (mounted) setState(() => _ubicacion = ubicacion);
  }

  Future<void> _seleccionarUbicacion() async {
    final cambiado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SeleccionarUbicacionScreen()),
    );
    if (cambiado == true) {
      _loadUbicacion();
    }
  }

  Future<void> _loadCategorias() async {
    try {
      final cats = await CategoriaService().getCategorias();
      if (mounted) {
        setState(() {
          _categorias = cats;
          _loadingCategorias = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorCategorias = 'No se pudieron cargar';
          _loadingCategorias = false;
        });
      }
    }
  }

  Future<void> _loadSolicitudesActivas() async {
    try {
      final todas = await SolicitudService().getMisSolicitudes();
      if (mounted) {
        setState(() {
          _solicitudesActivas = todas.where((s) => s.estaActiva).toList();
        });
      }
    } catch (_) {}
  }

  String get _ubicacionTexto {
    if (_ubicacion == null) return 'Obteniendo ubicación...';
    return _ubicacion!.nombre;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nombre = widget.usuario.nombreCompleto.isNotEmpty
        ? widget.usuario.nombreCompleto
        : widget.usuario.username;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 148,
              pinned: true,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Chamba',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $nombre 👋',
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _seleccionarUbicacion,
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _ubicacionTexto,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Buscador ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Buscar un servicio...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                      ),
                    ),
                  ),

                  // ── CTA ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _CtaButton(onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateSolicitudScreen()),
                      );
                    }),
                  ),

                  // ── Categorías ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: _SectionHeader(
                      title: _searchQuery.isEmpty
                          ? 'Servicios disponibles'
                          : 'Resultados de búsqueda',
                      actionLabel: _searchQuery.isEmpty ? 'Ver todas' : null,
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TodasCategoriasScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildCategoriasGrid(),

                  // ── Solicitudes activas ─────────────────────────
                  if (_solicitudesActivas.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
                      child: _SectionHeader(title: 'Tus solicitudes activas'),
                    ),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: _solicitudesActivas.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => _SolicitudCard(
                          solicitud: _solicitudesActivas[i],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalleSolicitudScreen(
                                  solicitud: _solicitudesActivas[i],
                                ),
                              ),
                            );
                            _loadSolicitudesActivas();
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriasGrid() {
    if (_loadingCategorias) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorCategorias != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorColor),
              const SizedBox(width: 10),
              Text(_errorCategorias!,
                  style: const TextStyle(color: AppTheme.errorColor)),
            ],
          ),
        ),
      );
    }
    if (_categorias.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('Sin categorías disponibles',
            style: TextStyle(color: AppTheme.textSubtitle)),
      );
    }

    final filtradas = _searchQuery.isEmpty
        ? _categorias
        : _categorias
            .where((c) => c.nombre.toLowerCase().contains(_searchQuery))
            .toList();

    if (filtradas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('No se encontraron servicios para "$_searchQuery"',
            style: const TextStyle(color: AppTheme.textSubtitle)),
      );
    }

    final visible = _searchQuery.isEmpty ? filtradas.take(6).toList() : filtradas;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.88,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: visible.length,
        itemBuilder: (_, i) => CategoriaCard(
          categoria: visible[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TrabajadoresCategoriaScreen(categoria: visible[i]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Componentes privados ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textTitle,
              ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios,
                    size: 12, color: AppTheme.primary),
              ],
            ),
          ),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CtaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.accent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.build_circle_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Qué necesitás arreglar?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Publicá tu solicitud en segundos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final Solicitud solicitud;
  final VoidCallback? onTap;
  const _SolicitudCard({required this.solicitud, this.onTap});

  Color get _colorEstado {
    if (solicitud.estado == 'abierta') return AppTheme.successColor;
    if (solicitud.estado == 'en_progreso') return AppTheme.secondary;
    return AppTheme.textSubtitle;
  }

  String get _estadoLabel =>
      solicitud.estado.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 220,
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _colorEstado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _estadoLabel,
              style: textTheme.labelSmall?.copyWith(
                color: _colorEstado,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                solicitud.titulo,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTitle,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (solicitud.categoriaNombre != null) ...[
                const SizedBox(height: 2),
                Text(
                  solicitud.categoriaNombre!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSubtitle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}

