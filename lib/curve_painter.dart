import 'package:flutter/material.dart';

class CurvePainter extends CustomPainter {
  final Color color;

  CurvePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    paint.style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.3, 0);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width * 0.8, size.height * 0.15);
    path.quadraticBezierTo(size.width * 1.1, size.height * 0.2, size.width * 0.9, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.6, size.width * 0.8, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.9, size.width * 0.7, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second layer with opacity
    final paint2 = Paint()..color = color.withOpacity(0.3);
    paint2.style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, 0);
    path2.lineTo(size.width * 0.4, 0);
    path2.quadraticBezierTo(size.width * 0.6, size.height * 0.05, size.width * 0.9, size.height * 0.1);
    path2.quadraticBezierTo(size.width * 1.2, size.height * 0.15, size.width, size.height * 0.3);
    path2.quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width * 0.9, size.height * 0.7);
    path2.quadraticBezierTo(size.width, size.height * 0.85, size.width * 0.8, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
