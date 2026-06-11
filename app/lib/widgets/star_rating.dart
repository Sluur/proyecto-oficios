import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int? total;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.total,
    this.size = 16,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final IconData icon;
          if (rating >= i + 1) {
            icon = Icons.star;
          } else if (rating >= i + 0.5) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          final star = Icon(icon, size: size, color: AppTheme.accent);
          if (onChanged == null) return star;
          return GestureDetector(
            onTap: () => onChanged!(i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: star,
            ),
          );
        }),
        if (total != null) ...[
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($total)',
            style: TextStyle(
              fontSize: size * 0.85,
              color: AppTheme.textSubtitle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
