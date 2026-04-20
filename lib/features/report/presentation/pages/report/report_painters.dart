part of 'report_page.dart';

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  const _ScoreRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const sw = 5.5;

    // 轨道：深绿半透
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
    // 进度：墨绿→草本绿
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF7EC8A0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

class _RiskIndexRingPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  const _RiskIndexRingPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6.5;
    const strokeWidth = 4.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final clampedProgress = progress.clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colors.first.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (clampedProgress <= 0) {
      return;
    }

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * clampedProgress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: colors,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskIndexRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        !listEquals(oldDelegate.colors, colors);
  }
}

// 新增：
class _HeroBgFillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制宣纸色背景，底部两角裁去 24px 圆角，
    // 让 Hero 的 ClipRRect 圆角能透出来
    const r = 24.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(r, size.height)
      ..arcToPoint(
        Offset(0, size.height - r),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFF4F1EB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HeroDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 保留右上角的纯白光晕，增加通透感
    canvas.drawCircle(
      Offset(size.width * 0.85, -20),
      120,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    // 保留左下角的微绿光晕，平衡画面
    canvas.drawCircle(
      Offset(-20, size.height * 0.9),
      90,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    // 彻底删除了那些突兀的线条 (canvas.drawLine 和 canvas.drawCircle)
    // 背景变得极其干净、柔和，这才是"新中式禅意"
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ConstitutionRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;
    const sides = 9;

    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.72,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF8FC7A5).withValues(alpha: 0.16),
                const Color(0xFFC9A84C).withValues(alpha: 0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.58, 1.0],
            ).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.9),
            ),
    );

    // 背景网格
    for (int ring = 1; ring <= 4; ring++) {
      final rr = r * ring / 4;
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = i * 2 * math.pi / sides - math.pi / 2;
        final x = cx + math.cos(angle) * rr;
        final y = cy + math.sin(angle) * rr;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // 数据 (对应9种体质)
    const scores = [0.72, 0.58, 0.25, 0.20, 0.30, 0.18, 0.15, 0.22, 0.10];

    // 数据填充
    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = i * 2 * math.pi / sides - math.pi / 2;
      final rr = r * scores[i];
      final x = cx + math.cos(angle) * rr;
      final y = cy + math.sin(angle) * rr;
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 轴线
    for (int i = 0; i < sides; i++) {
      final angle = i * 2 * math.pi / sides - math.pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r),
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.1)
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
