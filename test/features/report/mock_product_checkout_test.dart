import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/report/application/mock_product_checkout.dart';

void main() {
  group('buildMockOrderPreview', () {
    test('calculates subtotal and total with default shipping', () {
      final preview = buildMockOrderPreview(
        unitPriceCents: 5800,
        quantity: 2,
      );

      expect(preview.subtotalCents, 11600);
      expect(preview.shippingFeeCents, 1200);
      expect(preview.serviceFeeCents, 0);
      expect(preview.totalCents, 12800);
    });

    test('formats cents to price label safely', () {
      expect(formatPriceFromCents(8900), '¥89');
      expect(formatPriceFromCents(2990), '¥29.90');
    });
  });
}
