import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';

class FotoCaptureWidget extends StatefulWidget {
  final String tipo;
  final ValueChanged<XFile?> onFotoTomada;
  final XFile? fotoActual;

  const FotoCaptureWidget({
    super.key,
    required this.tipo,
    required this.onFotoTomada,
    this.fotoActual,
  });

  @override
  State<FotoCaptureWidget> createState() => _FotoCaptureWidgetState();
}

class _FotoCaptureWidgetState extends State<FotoCaptureWidget> {
  final _picker = ImagePicker();

  String _tipoLabel() {
    switch (widget.tipo) {
      case 'antes':
        return 'Foto ANTES de la visita';
      case 'durante':
        return 'Foto DURANTE la visita';
      case 'despues':
        return 'Foto DESPUÉS de la visita';
      default:
        return 'Foto';
    }
  }

  IconData _tipoIcon() {
    switch (widget.tipo) {
      case 'antes':
        return Icons.camera_front;
      case 'durante':
        return Icons.videocam;
      case 'despues':
        return Icons.camera_rear;
      default:
        return Icons.camera_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_tipoIcon(), size: 20, color: AppColors.guinda),
            const SizedBox(width: 8),
            Text(
              _tipoLabel(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: widget.fotoActual != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(widget.fotoActual!.path),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => widget.onFotoTomada(null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para tomar foto',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _tomarFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Cámara'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _tomarFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _tomarFoto(ImageSource source) async {
    try {
      final foto = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (foto != null) {
        widget.onFotoTomada(foto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar foto: $e')),
        );
      }
    }
  }
}
