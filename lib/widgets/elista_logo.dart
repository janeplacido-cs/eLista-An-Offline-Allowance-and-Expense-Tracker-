import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ElistaLogo extends StatelessWidget {
  const ElistaLogo({this.iconSize = 112, this.showTagline = true, super.key});

  final double iconSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = AppTextStyles.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(iconSize, iconSize),
          painter: _ElistaLogoPainter(colors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'eLista',
          style: textStyles.screenTitle.copyWith(
            color: colors.onSurface,
            letterSpacing: 0.2,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 2),
          Text(
            'Track Your Wallet, Every Peso',
            style: textStyles.caption.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ElistaLogoPainter extends CustomPainter {
  const _ElistaLogoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 112;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final phone = RRect.fromRectAndRadius(
      Rect.fromLTWH(38 * scale, 12 * scale, 42 * scale, 76 * scale),
      Radius.circular(7 * scale),
    );
    canvas.drawRRect(phone, paint);
    canvas.drawLine(
      Offset(49 * scale, 23 * scale),
      Offset(69 * scale, 23 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(49 * scale, 31 * scale),
      Offset(69 * scale, 31 * scale),
      paint,
    );
    canvas.drawCircle(Offset(59 * scale, 78 * scale), 1.7 * scale, paint);
    canvas.drawLine(
      Offset(8 * scale, 48 * scale),
      Offset(27 * scale, 48 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(14 * scale, 59 * scale),
      Offset(27 * scale, 59 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(20 * scale, 70 * scale),
      Offset(27 * scale, 70 * scale),
      paint,
    );
    final tail = Path()
      ..moveTo(80 * scale, 66 * scale)
      ..lineTo(93 * scale, 66 * scale)
      ..quadraticBezierTo(101 * scale, 66 * scale, 101 * scale, 75 * scale)
      ..lineTo(101 * scale, 89 * scale)
      ..quadraticBezierTo(101 * scale, 98 * scale, 92 * scale, 98 * scale)
      ..lineTo(46 * scale, 98 * scale)
      ..quadraticBezierTo(38 * scale, 98 * scale, 38 * scale, 90 * scale);
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant _ElistaLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
