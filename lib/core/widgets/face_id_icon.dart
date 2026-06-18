import 'package:flutter/material.dart';

/// A custom-drawn Face ID glyph (corner brackets + a simple face) since
/// Material has no equivalent icon.
class FaceIdIcon extends StatelessWidget {
  const FaceIdIcon({required this.size, required this.color, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FaceIdPainter(color: color, stroke: size * 0.06),
      ),
    );
  }
}

class _FaceIdPainter extends CustomPainter {
  const _FaceIdPainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    double u(double v) => v / 100 * s; // map a 0..100 grid to pixels

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const double m = 11; // margin from edge
    const double r = 17; // corner radius
    const double l = 12; // bracket arm length

    // Four corner brackets (rounded via quadratic at the corner vertex).
    final Path frame = Path()
      // top-left
      ..moveTo(u(m), u(m + r + l))
      ..lineTo(u(m), u(m + r))
      ..quadraticBezierTo(u(m), u(m), u(m + r), u(m))
      ..lineTo(u(m + r + l), u(m))
      // top-right
      ..moveTo(u(100 - m - r - l), u(m))
      ..lineTo(u(100 - m - r), u(m))
      ..quadraticBezierTo(u(100 - m), u(m), u(100 - m), u(m + r))
      ..lineTo(u(100 - m), u(m + r + l))
      // bottom-right
      ..moveTo(u(100 - m), u(100 - m - r - l))
      ..lineTo(u(100 - m), u(100 - m - r))
      ..quadraticBezierTo(
          u(100 - m), u(100 - m), u(100 - m - r), u(100 - m))
      ..lineTo(u(100 - m - r - l), u(100 - m))
      // bottom-left
      ..moveTo(u(m + r + l), u(100 - m))
      ..lineTo(u(m + r), u(100 - m))
      ..quadraticBezierTo(u(m), u(100 - m), u(m), u(100 - m - r))
      ..lineTo(u(m), u(100 - m - r - l));
    canvas.drawPath(frame, paint);

    // Eyes.
    canvas.drawLine(Offset(u(38), u(40)), Offset(u(38), u(50)), paint);
    canvas.drawLine(Offset(u(62), u(40)), Offset(u(62), u(50)), paint);

    // Nose (vertical stroke with a small hook).
    final Path nose = Path()
      ..moveTo(u(50), u(43))
      ..lineTo(u(50), u(57))
      ..lineTo(u(56), u(57));
    canvas.drawPath(nose, paint);

    // Smile.
    final Path smile = Path()
      ..moveTo(u(38), u(64))
      ..quadraticBezierTo(u(50), u(74), u(62), u(64));
    canvas.drawPath(smile, paint);
  }

  @override
  bool shouldRepaint(_FaceIdPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}
