import 'package:flutter/material.dart';
import '../models/trabajador.dart';
import '../theme/app_theme.dart';
import 'star_rating.dart';

class TrabajadorCard extends StatelessWidget {
  final Trabajador trabajador;
  final double? distanciaKm;
  final VoidCallback? onTap;

  const TrabajadorCard({
    super.key,
    required this.trabajador,
    this.distanciaKm,
    this.onTap,
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
              _Avatar(
                foto: trabajador.foto,
                nombre: trabajador.nombreCompleto,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trabajador.nombreCompleto,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textTitle,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trabajador.verificado) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 16, color: AppTheme.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (trabajador.oficios.isNotEmpty)
                      Text(
                        trabajador.oficios.map((o) => o.nombre).join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSubtitle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        StarRating(
                          rating: trabajador.promedioPuntaje ?? 0,
                          total: trabajador.totalResenas,
                          size: 13,
                        ),
                        if (distanciaKm != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppTheme.textSubtitle),
                          Text(
                            '${distanciaKm!.toStringAsFixed(1)} km',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSubtitle,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (trabajador.totalTrabajos > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${trabajador.totalTrabajos} trabajos completados',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSubtitle,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppTheme.textSubtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? foto;
  final String nombre;
  const _Avatar({required this.foto, required this.nombre});

  @override
  Widget build(BuildContext context) {
    if (foto != null && foto!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(foto!),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
