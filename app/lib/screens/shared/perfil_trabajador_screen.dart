import 'package:flutter/material.dart';
import '../../models/resena.dart';
import '../../models/trabajador.dart';
import '../../services/resena_service.dart';
import '../../services/trabajador_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/categoria_card.dart';
import '../../widgets/star_rating.dart';
import '../../utils/time_ago.dart';
import '../cliente/create_solicitud_screen.dart';

class PerfilTrabajadorScreen extends StatefulWidget {
  final int trabajadorId;
  const PerfilTrabajadorScreen({super.key, required this.trabajadorId});

  @override
  State<PerfilTrabajadorScreen> createState() =>
      _PerfilTrabajadorScreenState();
}

class _PerfilTrabajadorScreenState extends State<PerfilTrabajadorScreen> {
  Trabajador? _trabajador;
  List<Resena> _resenas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        TrabajadorService().getTrabajador(widget.trabajadorId),
        ResenaService().getResenasPorUsuario(widget.trabajadorId),
      ]);
      if (mounted) {
        setState(() {
          _trabajador = results[0] as Trabajador;
          _resenas = (results[1] as List).cast<Resena>().take(5).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_trabajador == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No se pudo cargar el perfil')),
      );
    }

    final t = _trabajador!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ver más trabajadores',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      _buildAvatar(t),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.nombreCompleto,
                            style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                          if (t.verificado) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                size: 18, color: Colors.white),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating
                  Center(
                    child: StarRating(
                      rating: t.promedioPuntaje ?? 0,
                      total: t.totalResenas,
                      size: 20,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${t.totalTrabajos} trabajos completados',
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSubtitle),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Oficios
                  if (t.oficios.isNotEmpty) ...[
                    Text('Servicios',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: t.oficios
                          .map((o) => Chip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(iconoParaCategoria(o.icono),
                                        size: 14, color: AppTheme.primary),
                                    const SizedBox(width: 4),
                                    Text(o.nombre),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Teléfono
                  if (t.telefono != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 16, color: AppTheme.textSubtitle),
                        const SizedBox(width: 6),
                        Text(t.telefono!,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSubtitle)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Reseñas
                  if (_resenas.isNotEmpty) ...[
                    Text('Reseñas de clientes',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ..._resenas.map((r) => _ResenaCard(resena: r)),
                    const SizedBox(height: 20),
                  ] else ...[
                    Center(
                      child: Text('Sin reseñas todavía',
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSubtitle)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
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
                  categoriaPreseleccionada: t.oficiosPrincipal,
                ),
              ),
            ),
            icon: const Icon(Icons.build_outlined),
            label: const Text('Solicitar servicio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Trabajador t) {
    if (t.foto != null && t.foto!.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(t.foto!),
      );
    }
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: Text(
        t.nombreCompleto.isNotEmpty ? t.nombreCompleto[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _ResenaCard extends StatelessWidget {
  final Resena resena;
  const _ResenaCard({required this.resena});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: resena.autorFoto != null
                    ? NetworkImage(resena.autorFoto!)
                    : null,
                child: resena.autorFoto == null
                    ? Text(
                        (resena.autorNombre?.isNotEmpty == true)
                            ? resena.autorNombre![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resena.autorNombre ?? 'Cliente',
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              StarRating(rating: resena.puntaje.toDouble(), size: 13),
            ],
          ),
          if (resena.comentario.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              resena.comentario,
              style:
                  textTheme.bodySmall?.copyWith(color: AppTheme.textSubtitle),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            timeAgo(resena.createdAt),
            style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textSubtitle, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
