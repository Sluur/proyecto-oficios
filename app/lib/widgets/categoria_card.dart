import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../theme/app_theme.dart';

IconData iconoParaCategoria(String icono) {
  const mapa = {
    'plumbing': Icons.plumbing,
    'electric_bolt': Icons.electric_bolt,
    'local_fire_department': Icons.local_fire_department,
    'format_paint': Icons.format_paint,
    'construction': Icons.construction,
    'local_shipping': Icons.local_shipping,
    'cleaning_services': Icons.cleaning_services,
    'lock': Icons.lock,
    'ac_unit': Icons.ac_unit,
    'carpenter': Icons.carpenter,
  };
  return mapa[icono] ?? Icons.handyman;
}

class CategoriaCard extends StatelessWidget {
  final Categoria categoria;
  final VoidCallback? onTap;

  const CategoriaCard({super.key, required this.categoria, this.onTap});

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconoParaCategoria(categoria.icono),
                size: 24,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                categoria.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTitle,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
