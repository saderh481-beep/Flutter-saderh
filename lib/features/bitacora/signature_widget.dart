import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SignatureWidget extends StatefulWidget {
  final ValueChanged<Uint8List?> onChanged;
  final Uint8List? initialBytes;
  final bool enabled;

  const SignatureWidget({
    super.key,
    required this.onChanged,
    this.initialBytes,
    this.enabled = true,
  });

  @override
  State<SignatureWidget> createState() => SignatureWidgetState();
}

class SignatureWidgetState extends State<SignatureWidget> {
  final List<List<Offset>> _points = [];
  List<Offset> _currentStroke = [];
  int _strokeCount = 0;
  final GlobalKey _painterKey = GlobalKey();

  void clear() {
    setState(() {
      _points.clear();
      _currentStroke.clear();
    });
    widget.onChanged(null);
  }

  Future<Uint8List?> getBytes() async {
    if (_points.isEmpty && _currentStroke.isEmpty) return null;
    final boundary = _painterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Firma del beneficiario', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            if (_points.isNotEmpty || _currentStroke.isNotEmpty)
              TextButton(
                onPressed: widget.enabled ? clear : null,
                child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        const SizedBox(height: 8),
      RepaintBoundary(
          key: _painterKey,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onPanStart: widget.enabled ? (details) {
                  setState(() {
                    _currentStroke = [details.localPosition];
                  });
                } : null,
                onPanUpdate: widget.enabled ? (details) {
                  setState(() {
                    _currentStroke.add(details.localPosition);
                  });
                } : null,
                onPanEnd: widget.enabled ? (details) {
                  setState(() {
                    if (_currentStroke.isNotEmpty) {
                      _points.add(List.from(_currentStroke));
                      _currentStroke = [];
                      _strokeCount++;
                    }
                  });
                  widget.onChanged(Uint8List(0));
                } : null,
                child: CustomPaint(
                  painter: _SignaturePainter(
                    strokes: _points,
                    currentStroke: _currentStroke,
                    version: _strokeCount,
                  ),
                  size: const Size(double.infinity, 150),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.enabled ? 'Firma aquí con tu dedo' : 'Toma la foto del rostro primero',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final int version;

  _SignaturePainter({required this.strokes, required this.currentStroke, required this.version});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.version != version;
}
