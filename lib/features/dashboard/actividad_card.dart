import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/actividad.dart';

class ActividadCard extends StatelessWidget {
  final Actividad actividad;
  final int index;
  final VoidCallback? onTap;

  const ActividadCard({
    super.key,
    required this.actividad,
    this.index = 0,
    this.onTap,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final color = actividad.activo ? AppColors.success : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  actividad.activo ? Icons.check_circle_outline : Icons.pause_circle_outlined,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actividad.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (actividad.descripcion != null)
                      Text(
                        actividad.descripcion!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (actividad.createdAt != null)
                      Text(
                        'Creada: ${_formatDate(actividad.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  actividad.activo ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 80).ms).fadeIn().slideY(begin: 0.2);
  }
}
