part of 'report_page.dart';

class _HeroPill extends StatelessWidget {
  final String label;
  final bool active;

  const _HeroPill({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // 鏍稿績锛氬幓闄?border锛屼娇鐢ㄩ€忔槑搴︽瀬浣庣殑绾噣搴曡壊
        color: active
            ? const Color(0xFF2D6A4F).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6), // 鐢ㄥ皬鍦嗚鏇夸唬鍛嗘澘鐨勫ぇ鑳跺泭
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active
              ? const Color(0xFF2D6A4F)
              : const Color(0xFF2D6A4F).withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
//  Tab 1 路 鎬昏
// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲

// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
//  Shared Sub-widgets
// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲

/// 鍗＄墖瀹瑰櫒
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FloatingSectionTitle extends StatelessWidget {
  final String title;

  const _FloatingSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFC9A84C),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalFocusBanner extends StatelessWidget {
  final String title;
  final String tag;
  final String subtitle;

  const _SeasonalFocusBanner({
    required this.title,
    required this.tag,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E0).withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC9A84C).withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8B6914),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: const Color(0xFF3A3028).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndentedDivider extends StatelessWidget {
  final double indent;

  const _IndentedDivider({required this.indent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(
        height: 1,
        width: double.infinity,
        color: Colors.grey.withValues(alpha: 0.10),
      ),
    );
  }
}

/// 鏌斿拰杩炵画娓愬彉杩涘害鏉?
class _SoftGradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final bool emphasize;
  final Color? trackColor;
  final List<Color>? fillColors;

  const _SoftGradientProgressBar({
    required this.value,
    this.height = 4,
    this.emphasize = false,
    this.trackColor,
    this.fillColors,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    final radius = Radius.circular(height);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color:
            trackColor ??
            (emphasize ? const Color(0xFFF6F7F2) : const Color(0xFFF8F7F3)),
        borderRadius: BorderRadius.all(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(radius),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress == 0 ? 0 : progress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors:
                      fillColors ??
                      const [
                        Color(0xFFD9EBDD),
                        Color(0xFFAED2B8),
                        Color(0xFF79B18C),
                      ],
                  stops: [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF79B18C).withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 涓夎瘖璇勫垎鍗曟牸
class _DiagScoreCell extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final IconData icon;
  final String desc;
  final Animation<double> anim;

  const _DiagScoreCell({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
    required this.desc,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: anim,
            builder: (context, child) => Text(
              '${(score * anim.value * 100).round()}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: anim,
            builder: (context, child) => _SoftGradientProgressBar(
              value: score * anim.value,
              height: 4,
              emphasize: true,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFF3A3028).withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 浜旇鐘舵€佹潯
class _WuxingBars extends StatelessWidget {
  const _WuxingBars();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = [
      (l10n.reportWuxingWood, 0.82, const Color(0xFF2D6A4F)),
      (l10n.reportWuxingFire, 0.55, const Color(0xFFD4794A)),
      (l10n.reportWuxingEarth, 0.68, const Color(0xFFC9A84C)),
      (l10n.reportWuxingMetal, 0.45, const Color(0xFF909080)),
      (l10n.reportWuxingWater, 0.60, const Color(0xFF4A7FA8)),
    ];

    return Column(
      children: data.map((d) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  d.$1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: d.$3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SoftGradientProgressBar(
                  value: d.$2,
                  height: 4,
                  emphasize: true,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  '${(d.$2 * 100).round()}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D6A4F),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

Future<void> _showReportUnlockSheet(
  BuildContext context, {
  required ValueListenable<ReportUnlockState> unlockStateListenable,
  required Future<void> Function() onPurchase,
  required Future<void> Function() onRestore,
}) async {
  final l10n = context.l10n;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFFF7F2E8).withValues(alpha: 0.12),
    isScrollControlled: true,
    builder: (context) {
      return ValueListenableBuilder<ReportUnlockState>(
        valueListenable: unlockStateListenable,
        builder: (context, unlockState, child) {
          if (unlockState.isUnlocked) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }

          final purchaseLabel = switch (unlockState.status) {
            ReportUnlockStatus.purchasing => l10n.reportUnlockSheetPurchasing,
            ReportUnlockStatus.restoring => l10n.reportUnlockSheetRestoring,
            _ => l10n.reportUnlockSheetConfirm,
          };

          final statusMessage = _resolveUnlockStatusMessage(l10n, unlockState);

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.82),
                              const Color(0xFFF9F4EC).withValues(alpha: 0.9),
                              const Color(0xFFF1F8F4).withValues(alpha: 0.92),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.56),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2D6A4F,
                              ).withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFFDDECE3,
                              ).withValues(alpha: 0.85),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -34,
                              right: -18,
                              child: Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(
                                        0xFFDAF0E1,
                                      ).withValues(alpha: 0.95),
                                      const Color(
                                        0xFFDAF0E1,
                                      ).withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -26,
                              bottom: -38,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(
                                        0xFFF3E8CF,
                                      ).withValues(alpha: 0.72),
                                      const Color(
                                        0xFFF3E8CF,
                                      ).withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                22,
                                22,
                                22,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _UnlockGlyph(size: 72),
                                  const SizedBox(height: 14),
                                  _UnlockTag(
                                    label: l10n.reportUnlockInvitationTag,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.reportUnlockSheetTitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E1810),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.reportUnlockInvitationSubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.7,
                                      color: const Color(
                                        0xFF3A3028,
                                      ).withValues(alpha: 0.74),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const _UnlockBenefitsCard(),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      12,
                                      14,
                                      12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.48,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF2D6A4F,
                                        ).withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          unlockState.displayPrice ??
                                              l10n.reportUnlockSheetPriceFallback,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF215840),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          l10n.reportUnlockSheetStoreHint,
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.55,
                                            color: const Color(
                                              0xFF7A6B5A,
                                            ).withValues(alpha: 0.85),
                                          ),
                                        ),
                                        if (statusMessage != null) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            statusMessage,
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.5,
                                              color:
                                                  unlockState.status ==
                                                      ReportUnlockStatus.error
                                                  ? const Color(0xFF9B4B4B)
                                                  : const Color(0xFF5E6C61),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _UnlockButton(
                                    label: purchaseLabel,
                                    isLoading: unlockState.isBusy,
                                    onTap: unlockState.isBusy
                                        ? null
                                        : () {
                                            unawaited(onPurchase());
                                          },
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: unlockState.isBusy
                                        ? null
                                        : () {
                                            unawaited(onRestore());
                                          },
                                    child: Text(
                                      l10n.reportUnlockRestoreButton,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2D6A4F)
                                            .withValues(
                                              alpha: unlockState.isBusy
                                                  ? 0.45
                                                  : 0.9,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String? _resolveUnlockStatusMessage(
  AppLocalizations l10n,
  ReportUnlockState unlockState,
) {
  return switch (unlockState.message) {
    'store-unavailable' => l10n.reportUnlockStatusStoreUnavailable,
    'product-not-found' => l10n.reportUnlockStatusProductUnavailable,
    'purchase-launch-failed' => l10n.reportUnlockStatusPurchaseFailed,
    'purchase-cancelled' => l10n.reportUnlockStatusPurchaseCancelled,
    'restore-not-found' => l10n.reportUnlockStatusRestoreNotFound,
    'purchase-stream-error' => l10n.reportUnlockStatusPurchaseFailed,
    'purchase-failed' => l10n.reportUnlockStatusPurchaseFailed,
    null => switch (unlockState.status) {
      ReportUnlockStatus.purchasing => l10n.reportUnlockStatusPurchasing,
      ReportUnlockStatus.restoring => l10n.reportUnlockStatusRestoring,
      ReportUnlockStatus.unavailable => l10n.reportUnlockStatusStoreUnavailable,
      _ => null,
    },
    _ => l10n.reportUnlockStatusPurchaseFailed,
  };
}

class _Lockable extends StatelessWidget {
  final bool isUnlocked;
  final String lockTitle;
  final Future<void> Function() onUnlock;
  final Widget child;

  const _Lockable({
    required this.isUnlocked,
    required this.lockTitle,
    required this.onUnlock,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) return child;

    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          ignoring: true,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Opacity(opacity: 0.72, child: child),
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      const Color(0xFFF6F2EA).withValues(alpha: 0.18),
                      const Color(0xFFF6F2EA).withValues(alpha: 0.34),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LockOverlay(title: lockTitle, onUnlock: onUnlock),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LockOverlay extends StatelessWidget {
  final String title;
  final Future<void> Function() onUnlock;

  const _LockOverlay({required this.title, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxHeight <= 300;
            final isVeryTight = constraints.maxHeight <= 245;

            return Container(
              constraints: const BoxConstraints(maxWidth: 332),
              padding: EdgeInsets.fromLTRB(
                isVeryTight ? 16 : 20,
                isVeryTight ? 16 : 20,
                isVeryTight ? 16 : 20,
                isVeryTight ? 14 : 18,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.78),
                    const Color(0xFFF8F3EA).withValues(alpha: 0.86),
                    const Color(0xFFF0F7F2).withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UnlockGlyph(size: isVeryTight ? 42 : 56),
                  SizedBox(height: isVeryTight ? 8 : 12),
                  if (!isVeryTight) ...[
                    _UnlockTag(label: l10n.reportUnlockInvitationTag),
                    SizedBox(height: isTight ? 8 : 12),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: isVeryTight ? 2 : null,
                    overflow: isVeryTight ? TextOverflow.ellipsis : null,
                    style: TextStyle(
                      fontSize: isVeryTight ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1810),
                      letterSpacing: 0.2,
                      height: isVeryTight ? 1.25 : 1.3,
                    ),
                  ),
                  SizedBox(height: isVeryTight ? 6 : 8),
                  Text(
                    l10n.reportUnlockDescription,
                    textAlign: TextAlign.center,
                    maxLines: isVeryTight ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isVeryTight ? 11 : 12,
                      height: isVeryTight ? 1.45 : 1.65,
                      color: const Color(0xFF3A3028).withValues(alpha: 0.66),
                    ),
                  ),
                  SizedBox(height: isVeryTight ? 10 : 14),
                  _UnlockBenefitsCard(
                    compact: true,
                    maxItems: isVeryTight ? 1 : (isTight ? 2 : 3),
                  ),
                  SizedBox(height: isVeryTight ? 10 : 14),
                  _UnlockButton(
                    label: l10n.reportUnlockButton,
                    onTap: () {
                      unawaited(onUnlock());
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UnlockGlyph extends StatelessWidget {
  final double size;

  const _UnlockGlyph({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFEEF7F1).withValues(alpha: 0.96),
            const Color(0xFFE2F0E7).withValues(alpha: 0.88),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.spa_outlined,
            size: size * 0.42,
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.92),
          ),
          Positioned(
            top: size * 0.22,
            right: size * 0.18,
            child: Icon(
              Icons.lock_outline_rounded,
              size: size * 0.2,
              color: const Color(0xFF6B5B95).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockTag extends StatelessWidget {
  final String label;

  const _UnlockTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6F1).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _UnlockBenefitsCard extends StatelessWidget {
  final bool compact;
  final int maxItems;

  const _UnlockBenefitsCard({this.compact = false, this.maxItems = 3});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final benefits = [
      l10n.reportUnlockBenefitConstitution,
      l10n.reportUnlockBenefitTherapy,
      l10n.reportUnlockBenefitAdvice,
    ].take(maxItems).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 12 : 14,
        compact ? 14 : 16,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: List.generate(benefits.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == benefits.length - 1 ? 0 : (compact ? 10 : 12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 20 : 22,
                  height: compact ? 20 : 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF78B99A).withValues(alpha: 0.95),
                        const Color(0xFF2D6A4F),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: compact ? 12 : 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    benefits[index],
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11.5 : 12.5,
                      height: compact ? 1.5 : 1.6,
                      color: const Color(0xFF2B241D).withValues(alpha: 0.84),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _UnlockButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8FC9AE), Color(0xFF3E8E6C), Color(0xFF1F6447)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D6A4F).withValues(alpha: 0.26),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF9DCCB7).withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 1,
                right: 1,
                top: 1,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.34),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 閿€间俊鎭
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFFA09080).withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1810),
          ),
        ),
      ],
    );
  }
}

/// 浣撹川璇勫垎琛岋紙Tab2 闆疯揪涓嬫柟鍒楄〃锛?
class _ConstitutionScoreRow extends StatefulWidget {
  final String label;
  final double score;
  final Color color;
  final bool isMain;

  const _ConstitutionScoreRow({
    required this.label,
    required this.score,
    required this.color,
    required this.isMain,
  });

  @override
  State<_ConstitutionScoreRow> createState() => _ConstitutionScoreRowState();
}

class _ConstitutionScoreRowState extends State<_ConstitutionScoreRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(
      const Duration(milliseconds: 300),
      () => mounted ? _ctrl.forward() : null,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSecondaryLow = !widget.isMain && widget.score < 0.28;

    return Row(
      children: [
        if (widget.isMain)
          Container(
            width: 4,
            height: 16,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.isMain ? FontWeight.w700 : FontWeight.w400,
              color: widget.isMain
                  ? const Color(0xFF1E1810)
                  : (isSecondaryLow
                        ? const Color(0xFFA09080).withValues(alpha: 0.72)
                        : const Color(0xFFA09080)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => _SoftGradientProgressBar(
              value: widget.score * _anim.value,
              height: widget.isMain ? 4 : 3,
              emphasize: widget.isMain,
              trackColor: isSecondaryLow ? Colors.transparent : null,
              fillColors: widget.isMain
                  ? const [
                      Color(0xFFD7EFD9),
                      Color(0xFFA9D6B5),
                      Color(0xFF74B58A),
                    ]
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => Text(
              '${(widget.score * _anim.value * 100).round()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.isMain ? FontWeight.w700 : FontWeight.w400,
                color: widget.isMain
                    ? const Color(0xFF2D6A4F)
                    : (isSecondaryLow
                          ? const Color(0xFFA09080).withValues(alpha: 0.7)
                          : const Color(0xFF6E8E7A)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 绌翠綅鍗＄墖
class _AcuPointCard extends StatelessWidget {
  final _AcuPoint point;
  const _AcuPointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: point.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: point.color.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          point.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: point.color,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          point.meridian,
                          style: TextStyle(
                            fontSize: 11,
                            color: point.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: const Color(0xFFA09080),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            point.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA09080),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.effect,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 椋熸潗 Chip
class _FoodChip extends StatelessWidget {
  final String name;
  final String desc;
  final Color color;

  const _FoodChip({
    required this.name,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF3A3028).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 浜у搧鎺ㄨ崘鍗＄墖
class _ProductCard extends StatelessWidget {
  final ReportProductData product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.reportProductDetail, extra: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: product.color.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: product.color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(product.icon, size: 24, color: product.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                        ),
                        Text(
                          product.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: product.color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.priceLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: product.color,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: product.color.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.reportAdviceProductDetailButton,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.color.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
//  Data Models
// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲

class _AcuPoint {
  final String name;
  final String location;
  final String effect;
  final String meridian;
  final Color color;

  const _AcuPoint({
    required this.name,
    required this.location,
    required this.effect,
    required this.meridian,
    required this.color,
  });
}

class _SeasonData {
  final String name;
  final Color color;
  final Color lightColor;
  final String advice;
  final String avoid;

  const _SeasonData({
    required this.name,
    required this.color,
    required this.lightColor,
    required this.advice,
    required this.avoid,
  });
}

// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
//  Painters
// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
