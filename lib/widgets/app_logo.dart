import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showLabel;
  const AppLogo({super.key, this.size = 64, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LogoPainter()),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _LogoPainter()),
        ),
        const SizedBox(height: 6),
        Text(
          'HealthGuard',
          style: TextStyle(
            fontSize: size * 0.22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    // ── Fond cercle dégradé bleu ────────────────────────────────
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF1E88E5), Color(0xFF0D47A1)],
        center: Alignment.center,
        radius: 0.85,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(cx, cy), w / 2, bgPaint);

    // ── Cœur blanc ──────────────────────────────────────────────
    final heartPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final heartPath = _buildHeart(cx, cy * 0.88, w * 0.36);
    canvas.drawPath(heartPath, heartPaint);

    // ── Ligne ECG blanche ────────────────────────────────────────
    final ecgPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.048
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final ecgPath = _buildECG(w, h);
    canvas.drawPath(ecgPath, ecgPaint);
  }

  Path _buildHeart(double cx, double cy, double r) {
    // Deux cercles (les bosses) + triangle (la pointe)
    final path = Path();

    // Bosse gauche
    path.addOval(Rect.fromCircle(
      center: Offset(cx - r * 0.52, cy),
      radius: r * 0.55,
    ));

    // Bosse droite
    path.addOval(Rect.fromCircle(
      center: Offset(cx + r * 0.52, cy),
      radius: r * 0.55,
    ));

    // Triangle bas (pointe)
    path.addPolygon([
      Offset(cx - r * 1.04, cy + r * 0.22),
      Offset(cx + r * 1.04, cy + r * 0.22),
      Offset(cx, cy + r * 1.88),
    ], true);

    return path;
  }

  Path _buildECG(double w, double h) {
    final y0 = h * 0.76;
    return Path()
      ..moveTo(w * 0.055, y0)
      ..lineTo(w * 0.28,  y0)
      ..lineTo(w * 0.33,  y0 - h * 0.08)
      ..lineTo(w * 0.375, y0 + h * 0.10)
      ..lineTo(w * 0.42,  y0 - h * 0.19)
      ..lineTo(w * 0.46,  y0)
      ..lineTo(w * 0.945, y0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
