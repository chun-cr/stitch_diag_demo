import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';

class ScanGuidePage extends StatelessWidget {
  const ScanGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('AI 健康扫描'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Guide Cards
              _buildStepCard(
                step: 1,
                title: '面部扫描',
                desc: '分析面色光泽与五官特征',
                icon: Icons.face_retouching_natural_outlined,
                color: AppColors.primary,
                isCompleted: false,
                isLast: false,
              ),
              _buildStepCard(
                step: 2,
                title: '舌头扫描',
                desc: '观察舌质颜色与舌苔厚薄',
                icon: Icons.sentiment_satisfied_alt_outlined,
                color: AppColors.secondary,
                isCompleted: false,
                isLast: false,
              ),
              _buildStepCard(
                step: 3,
                title: '手掌扫描',
                desc: '识别掌纹分布与局部气色',
                icon: Icons.back_hand_outlined,
                color: const Color(0xFF9B8EF0),
                isCompleted: false,
                isLast: true,
              ),
              
              const Spacer(),
              
              // Bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  const Text('预计 3 分钟完成 · 请在光线充足处进行', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => context.push(AppRoutes.scanFace),
                  child: const Text('开始扫描', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('扫描数据仅用于健康分析，不会上传至第三方', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    required bool isLast,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('步骤 $step：$title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle, 
                size: 24, 
                color: isCompleted ? AppColors.secondary : AppColors.textHint.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        // Connection Line
        if (!isLast)
          Container(
            height: 24,
            margin: const EdgeInsets.only(left: 44),
            child: CustomPaint(
               painter: _DashedLinePainter(),
            ),
          ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
       ..color = AppColors.borderColor
       ..strokeWidth = 1.5
       ..style = PaintingStyle.stroke;

    double startY = 0;
    while(startY < size.height) {
       canvas.drawLine(Offset(0, startY), Offset(0, startY + 4), paint);
       startY += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
