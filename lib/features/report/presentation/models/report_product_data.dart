import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

@immutable
class ReportProductData {
  final String id;
  final String name;
  final String type;
  final String description;
  final int priceCents;
  final String tag;
  final Color color;
  final IconData icon;
  final String packageNote;
  final String shippingNote;

  const ReportProductData({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.priceCents,
    required this.tag,
    required this.color,
    required this.icon,
    required this.packageNote,
    required this.shippingNote,
  });

  String get priceLabel {
    final yuan = priceCents ~/ 100;
    final fen = priceCents % 100;
    if (fen == 0) {
      return '¥$yuan';
    }
    return '¥$yuan.${fen.toString().padLeft(2, '0')}';
  }
}

List<ReportProductData> buildReportProducts(AppLocalizations l10n) {
  return [
    ReportProductData(
      id: 'jianpiwan',
      name: l10n.reportProductJianpiwan,
      type: l10n.reportProductJianpiwanType,
      description: l10n.reportProductJianpiwanDesc,
      priceCents: 5800,
      tag: l10n.reportProductJianpiwanTag,
      color: const Color(0xFF2D6A4F),
      icon: Icons.local_pharmacy_outlined,
      packageNote: l10n.reportProductJianpiwanPack,
      shippingNote: l10n.reportProductCommonShipping,
    ),
    ReportProductData(
      id: 'shenling',
      name: l10n.reportProductShenling,
      type: l10n.reportProductShenlingType,
      description: l10n.reportProductShenlingDesc,
      priceCents: 4500,
      tag: l10n.reportProductShenlingTag,
      color: const Color(0xFF0D7A5A),
      icon: Icons.eco_outlined,
      packageNote: l10n.reportProductShenlingPack,
      shippingNote: l10n.reportProductCommonShipping,
    ),
    ReportProductData(
      id: 'aijiu',
      name: l10n.reportProductAijiu,
      type: l10n.reportProductAijiuType,
      description: l10n.reportProductAijiuDesc,
      priceCents: 12800,
      tag: l10n.reportProductAijiuTag,
      color: const Color(0xFFC9A84C),
      icon: Icons.spa_outlined,
      packageNote: l10n.reportProductAijiuPack,
      shippingNote: l10n.reportProductCommonShipping,
    ),
    ReportProductData(
      id: 'food-pack',
      name: l10n.reportProductFoodPack,
      type: l10n.reportProductFoodPackType,
      description: l10n.reportProductFoodPackDesc,
      priceCents: 8900,
      tag: l10n.reportProductFoodPackTag,
      color: const Color(0xFF6B5B95),
      icon: Icons.restaurant_menu_outlined,
      packageNote: l10n.reportProductFoodPackPack,
      shippingNote: l10n.reportProductCommonShipping,
    ),
  ];
}
