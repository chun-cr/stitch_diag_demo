import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';

@immutable
class ReportProductData {
  final String id;
  final String? detailId;
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
    this.detailId,
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

  bool get supportsRemoteDetail => (detailId?.trim().isNotEmpty ?? false);

  factory ReportProductData.fromBackend(
    Map<String, dynamic> json, {
    int index = 0,
  }) {
    final resolvedDetailId = _resolveDetailId(json);
    return ReportProductData(
      id: resolvedDetailId ?? 'backend-$index',
      detailId: resolvedDetailId,
      name:
          _firstText(json, const [
            'name',
            'productName',
            'spuName',
            'skuName',
            'title',
          ]) ??
          '推荐商品',
      type:
          _firstText(json, const [
            'type',
            'typeName',
            'categoryName',
            'productType',
          ]) ??
          _kBackendDefaultType,
      description:
          _firstText(json, const [
            'description',
            'desc',
            'detail',
            'recommendationReason',
            'reason',
            'summary',
          ]) ??
          _kBackendDefaultDescription,
      priceCents: _resolvePriceCents(json),
      tag:
          _firstText(json, const [
            'tag',
            'label',
            'badge',
            'recommendTag',
            'sceneTag',
          ]) ??
          (index == 0 ? '推荐' : '精选'),
      color: _resolveColor(json, index),
      icon: _resolveIcon(json, index),
      packageNote:
          _firstText(json, const [
            'packageNote',
            'packageDesc',
            'specification',
            'spec',
            'packageInfo',
          ]) ??
          _kBackendDefaultPackageNote,
      shippingNote:
          _firstText(json, const [
            'shippingNote',
            'shippingDesc',
            'deliveryDesc',
            'logisticsDesc',
            'deliveryInfo',
          ]) ??
          _kBackendDefaultShippingNote,
    );
  }

  ReportProductData mergeBackend(Map<String, dynamic> json) {
    final resolvedDetailId = _resolveDetailId(json);
    return ReportProductData(
      id: resolvedDetailId ?? id,
      detailId: resolvedDetailId ?? detailId,
      name:
          _firstText(json, const [
            'name',
            'productName',
            'spuName',
            'skuName',
            'title',
          ]) ??
          name,
      type:
          _firstText(json, const [
            'type',
            'typeName',
            'categoryName',
            'productType',
          ]) ??
          type,
      description:
          _firstText(json, const [
            'description',
            'desc',
            'detail',
            'recommendationReason',
            'reason',
            'summary',
          ]) ??
          description,
      priceCents: _tryResolvePriceCents(json) ?? priceCents,
      tag:
          _firstText(json, const [
            'tag',
            'label',
            'badge',
            'recommendTag',
            'sceneTag',
          ]) ??
          tag,
      color: _tryResolveColor(json) ?? color,
      icon: _tryResolveIcon(json) ?? icon,
      packageNote:
          _firstText(json, const [
            'packageNote',
            'packageDesc',
            'specification',
            'spec',
            'packageInfo',
          ]) ??
          packageNote,
      shippingNote:
          _firstText(json, const [
            'shippingNote',
            'shippingDesc',
            'deliveryDesc',
            'logisticsDesc',
            'deliveryInfo',
          ]) ??
          shippingNote,
    );
  }
}

const _kBackendFallbackColors = <Color>[
  Color(0xFF2D6A4F),
  Color(0xFF0D7A5A),
  Color(0xFFC9A84C),
  Color(0xFF6B5B95),
  Color(0xFF4A7FA8),
  Color(0xFFD4794A),
];

const _kBackendDefaultDescription = '基于报告结果推荐的适配商品。';
const _kBackendDefaultType = '推荐商品';
const _kBackendDefaultPackageNote = '以实际发货规格为准。';
const _kBackendDefaultShippingNote = '支持快递配送，具体以页面说明为准。';

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

String? _resolveDetailId(Map<String, dynamic> json) {
  return _firstText(json, const [
    'id',
    'productId',
    'spuId',
    'skuId',
    'itemId',
    'code',
  ]);
}

String? _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

int _resolvePriceCents(Map<String, dynamic> json) {
  return _tryResolvePriceCents(json) ?? 0;
}

int? _tryResolvePriceCents(Map<String, dynamic> json) {
  const minorKeys = [
    'priceMinor',
    'salePriceMinor',
    'currentPriceMinor',
    'amountMinor',
    'unitPriceMinor',
    'marketPriceMinor',
    'originalPriceMinor',
  ];
  for (final key in minorKeys) {
    final cents = _parseMoneyValue(json[key]);
    if (cents != null) {
      return cents.round();
    }
  }

  const yuanKeys = [
    'price',
    'salePrice',
    'currentPrice',
    'amount',
    'unitPrice',
    'marketPrice',
    'originalPrice',
  ];
  for (final key in yuanKeys) {
    final yuan = _parseMoneyValue(json[key]);
    if (yuan != null) {
      return (yuan * 100).round();
    }
  }

  return null;
}

double? _parseMoneyValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.\-]'), '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }
  return null;
}

Color _resolveColor(Map<String, dynamic> json, int index) {
  return _tryResolveColor(json) ??
      _kBackendFallbackColors[index % _kBackendFallbackColors.length];
}

Color? _tryResolveColor(Map<String, dynamic> json) {
  for (final key in const ['color', 'themeColor', 'brandColor', 'mainColor']) {
    final color = _parseColorValue(json[key]);
    if (color != null) {
      return color;
    }
  }
  return null;
}

Color? _parseColorValue(Object? value) {
  if (value is Color) {
    return value;
  }
  if (value is int) {
    return Color(value);
  }
  if (value is String) {
    var hex = value.trim();
    if (hex.isEmpty) {
      return null;
    }
    hex = hex
        .replaceFirst('#', '')
        .replaceFirst('0x', '')
        .replaceFirst('0X', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) {
      return null;
    }
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return null;
    }
    return Color(parsed);
  }
  return null;
}

IconData _resolveIcon(Map<String, dynamic> json, int index) {
  return _tryResolveIcon(json) ??
      switch (index % 4) {
        0 => Icons.local_pharmacy_outlined,
        1 => Icons.eco_outlined,
        2 => Icons.spa_outlined,
        _ => Icons.restaurant_menu_outlined,
      };
}

IconData? _tryResolveIcon(Map<String, dynamic> json) {
  final hint = [
    _firstText(json, const ['icon', 'iconName', 'iconKey']),
    _firstText(json, const ['category', 'categoryName', 'type', 'typeName']),
    _firstText(json, const ['name', 'title', 'description']),
  ].whereType<String>().join(' ').toLowerCase();

  if (hint.trim().isEmpty) {
    return null;
  }

  if (hint.contains('pharmacy') ||
      hint.contains('medicine') ||
      hint.contains('drug') ||
      hint.contains('药') ||
      hint.contains('丸') ||
      hint.contains('胶')) {
    return Icons.local_pharmacy_outlined;
  }

  if (hint.contains('food') ||
      hint.contains('diet') ||
      hint.contains('meal') ||
      hint.contains('饮') ||
      hint.contains('食') ||
      hint.contains('汤') ||
      hint.contains('粥')) {
    return Icons.restaurant_menu_outlined;
  }

  if (hint.contains('device') ||
      hint.contains('equip') ||
      hint.contains('instrument') ||
      hint.contains('thera') ||
      hint.contains('理疗') ||
      hint.contains('器') ||
      hint.contains('仪')) {
    return Icons.medical_services_outlined;
  }

  if (hint.contains('eco') ||
      hint.contains('herb') ||
      hint.contains('tea') ||
      hint.contains('草') ||
      hint.contains('养生') ||
      hint.contains('植物')) {
    return Icons.eco_outlined;
  }

  if (hint.contains('spa') ||
      hint.contains('massage') ||
      hint.contains('灸') ||
      hint.contains('艾')) {
    return Icons.spa_outlined;
  }

  return null;
}
