import 'package:flutter/material.dart';

/// NutriAI premium logo widget.
/// Renders purely in Flutter — no image files, scales perfectly at any size.
/// Usage:
///   NutriLogo(size: 64)                  // default square
///   NutriLogo(size: 48, showText: true)  // icon + "NutriAI" text below
class NutriLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool darkText;

  const NutriLogo({
    super.key,
    this.size = 56,
    this.showText = false,
    this.darkText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _LogoPainter()),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.12),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF7C5CFC), Color(0xFFB06EFF)],
            ).createShader(bounds),
            child: Text(
              'NutriAI',
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: darkText ? const Color(0xFF1E1B4B) : Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Rect.fromLTWH(0, 0, s, s);

    // ── Background rounded square ──────────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7C5CFC), Color(0xFFB06EFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22));
    canvas.drawRRect(rrect, bgPaint);

    // Subtle inner shine top-left
    final shinePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.2,
        colors: [Colors.white.withOpacity(0.22), Colors.transparent],
      ).createShader(rect);
    canvas.drawRRect(rrect, shinePaint);

    // ── Bowl rim ───────────────────────────────────────────────
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final rimLeft   = s * 0.19;
    final rimRight  = s * 0.76;
    final rimTop    = s * 0.44;
    final rimHeight = s * 0.09;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rimLeft, rimTop, rimRight - rimLeft, rimHeight),
        Radius.circular(rimHeight / 2),
      ),
      rimPaint,
    );

    // ── Bowl body (half ellipse) ───────────────────────────────
    final bowlPaint = Paint()
      ..color = Colors.white.withOpacity(0.93)
      ..style = PaintingStyle.fill;

    final bowlRect = Rect.fromLTWH(
      rimLeft,
      rimTop + rimHeight * 0.4,
      rimRight - rimLeft,
      s * 0.30,
    );

    // Clip to only draw the bottom half of the ellipse
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, rimTop + rimHeight * 0.4, s, s));
    canvas.drawOval(bowlRect, bowlPaint);
    canvas.restore();

    // ── Steam lines ────────────────────────────────────────────
    final steamPaint = Paint()
      ..color = Colors.white.withOpacity(0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final cx = s * (0.30 + i * 0.165);
      final path = Path();
      path.moveTo(cx, rimTop - s * 0.06);
      path.cubicTo(
        cx + s * 0.04, rimTop - s * 0.14,
        cx - s * 0.04, rimTop - s * 0.22,
        cx,            rimTop - s * 0.30,
      );
      canvas.drawPath(path, steamPaint);
    }

    // ── Fork (right side) ─────────────────────────────────────
    final forkPaint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.fill;

    final fx     = s * 0.815;
    final fTop   = s * 0.16;
    final fBot   = s * 0.52;
    final fWidth = s * 0.026;

    // Handle (single rod)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(fx - fWidth, s * 0.32, fWidth * 2, fBot - s * 0.32),
        Radius.circular(fWidth),
      ),
      forkPaint,
    );

    // Three tines
    final tineGap = fWidth * 2.2;
    for (int t = -1; t <= 1; t++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            fx + t * tineGap - fWidth * 0.7,
            fTop,
            fWidth * 1.4,
            s * 0.17,
          ),
          Radius.circular(fWidth * 0.7),
        ),
        forkPaint,
      );
    }

    // Tine connector bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          fx - tineGap - fWidth * 0.7,
          fTop + s * 0.15,
          tineGap * 2 + fWidth * 1.4,
          fWidth * 1.5,
        ),
        Radius.circular(fWidth * 0.7),
      ),
      forkPaint,
    );

    // ── Food dots inside bowl ──────────────────────────────────
    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    final dotData = [
      [s * 0.35, s * 0.635, s * 0.038, const Color(0xFFB06EFF), 0.7],
      [s * 0.505, s * 0.665, s * 0.030, const Color(0xFF9B7EFF), 0.6],
      [s * 0.645, s * 0.635, s * 0.038, const Color(0xFFB06EFF), 0.7],
    ];

    for (final d in dotData) {
      dotPaint.color = (d[3] as Color).withOpacity(d[4] as double);
      canvas.drawCircle(Offset(d[0] as double, d[1] as double), d[2] as double, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}