import 'package:flutter/foundation.dart';

@immutable
class OrderPreview {
  final int unitPriceCents;
  final int quantity;
  final int subtotalCents;
  final int shippingFeeCents;
  final int serviceFeeCents;
  final int totalCents;

  const OrderPreview({
    required this.unitPriceCents,
    required this.quantity,
    required this.subtotalCents,
    required this.shippingFeeCents,
    required this.serviceFeeCents,
    required this.totalCents,
  });
}

OrderPreview buildMockOrderPreview({
  required int unitPriceCents,
  required int quantity,
  int shippingFeeCents = 1200,
  int serviceFeeCents = 0,
}) {
  final subtotalCents = unitPriceCents * quantity;
  return OrderPreview(
    unitPriceCents: unitPriceCents,
    quantity: quantity,
    subtotalCents: subtotalCents,
    shippingFeeCents: shippingFeeCents,
    serviceFeeCents: serviceFeeCents,
    totalCents: subtotalCents + shippingFeeCents + serviceFeeCents,
  );
}

String formatPriceFromCents(int cents) {
  final yuan = cents ~/ 100;
  final fen = cents % 100;
  if (fen == 0) {
    return '¥$yuan';
  }
  return '¥$yuan.${fen.toString().padLeft(2, '0')}';
}
