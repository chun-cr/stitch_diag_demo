import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/features/report/application/mock_product_checkout.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report_product_detail_page.dart';

class ReportCheckoutPage extends StatefulWidget {
  final ReportCheckoutArgs args;

  const ReportCheckoutPage({
    super.key,
    required this.args,
  });

  @override
  State<ReportCheckoutPage> createState() => _ReportCheckoutPageState();
}

class _ReportCheckoutPageState extends State<ReportCheckoutPage> {
  late final TextEditingController _recipientController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isSubmitting = false;
  bool _isSubmittedMock = false;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: '陈清和');
    _phoneController = TextEditingController(text: '13800001234');
    _addressController = TextEditingController(
      text: '上海市徐汇区漕溪北路 88 号 18 楼',
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _recipientController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty;
  }

  void _showPaymentPlaceholderDialog({
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.commonConfirm),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final product = widget.args.product;
    final preview = buildMockOrderPreview(
      unitPriceCents: product.priceCents,
      quantity: widget.args.quantity,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.reportProductCheckoutTitle),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ApplePayPlaceholder(
                enabled: !_isSubmitting,
                title: l10n.reportProductCheckoutApplePayTitle,
                onTap: () => _showPaymentPlaceholderDialog(
                  title: l10n.reportProductCheckoutApplePayTitle,
                  body: l10n.reportProductCheckoutApplePayDialogBody,
                ),
              ),
              const SizedBox(height: 10),
              _GooglePayPlaceholder(
                enabled: !_isSubmitting,
                title: l10n.reportProductCheckoutGooglePayTitle,
                onTap: () => _showPaymentPlaceholderDialog(
                  title: l10n.reportProductCheckoutGooglePayTitle,
                  body: l10n.reportProductCheckoutGooglePayDialogBody,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: (!_canSubmit || _isSubmitting)
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 650),
                        );
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _isSubmitting = false;
                          _isSubmittedMock = true;
                        });
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        product.color.withValues(
                          alpha: (!_canSubmit || _isSubmitting) ? 0.45 : 0.86,
                        ),
                        product.color.withValues(
                          alpha: (!_canSubmit || _isSubmitting) ? 0.45 : 1,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting) ...[
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
                      Text(
                        _isSubmitting
                            ? l10n.reportProductCheckoutSubmitting
                            : l10n.reportProductCheckoutMockSubmit,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_isSubmittedMock) ...[
            _SuccessCard(productColor: product.color),
            const SizedBox(height: 16),
          ],
          _CheckoutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckoutSectionTitle(
                  title: l10n.reportProductCheckoutSectionAddress,
                  color: product.color,
                ),
                const SizedBox(height: 12),
                _CheckoutField(
                  label: l10n.reportProductCheckoutRecipient,
                  controller: _recipientController,
                ),
                const SizedBox(height: 12),
                _CheckoutField(
                  label: l10n.reportProductCheckoutPhone,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _CheckoutField(
                  label: l10n.reportProductCheckoutAddress,
                  controller: _addressController,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckoutSectionTitle(
                  title: l10n.reportProductCheckoutOrderSummary,
                  color: product.color,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: product.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(product.icon, color: product.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.reportProductCheckoutQuantityLabel}: ${widget.args.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF3A3028).withValues(alpha: 0.62),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      product.priceLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: product.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _AmountRow(
                  label: l10n.reportProductCheckoutSubtotal,
                  value: formatPriceFromCents(preview.subtotalCents),
                ),
                const SizedBox(height: 8),
                _AmountRow(
                  label: l10n.reportProductCheckoutShippingFee,
                  value: formatPriceFromCents(preview.shippingFeeCents),
                ),
                const SizedBox(height: 8),
                _AmountRow(
                  label: l10n.reportProductCheckoutServiceFee,
                  value: formatPriceFromCents(preview.serviceFeeCents),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _AmountRow(
                  label: l10n.reportProductCheckoutTotal,
                  value: formatPriceFromCents(preview.totalCents),
                  emphasize: true,
                  color: product.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckoutSectionTitle(
                  title: l10n.reportProductCheckoutPaymentTitle,
                  color: product.color,
                ),
                const SizedBox(height: 12),
                _PaymentMethodCard(
                  title: l10n.reportProductCheckoutApplePayTitle,
                  subtitle: l10n.reportProductCheckoutApplePaySubtitle,
                  icon: CupertinoIcons.creditcard_fill,
                  dark: true,
                ),
                const SizedBox(height: 10),
                _PaymentMethodCard(
                  title: l10n.reportProductCheckoutGooglePayTitle,
                  subtitle: l10n.reportProductCheckoutGooglePaySubtitle,
                  icon: Icons.account_balance_wallet_rounded,
                  dark: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  final Widget child;

  const _CheckoutCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _CheckoutSectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _CheckoutSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1810),
          ),
        ),
      ],
    );
  }
}

class _CheckoutField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _CheckoutField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 13 : 12,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF3A3028).withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 18 : 13,
            fontWeight: FontWeight.w700,
            color: color ?? const Color(0xFF1E1810),
          ),
        ),
      ],
    );
  }
}

class _ApplePayPlaceholder extends StatelessWidget {
  final bool enabled;
  final String title;
  final VoidCallback onTap;

  const _ApplePayPlaceholder({
    required this.enabled,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.creditcard_fill, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GooglePayPlaceholder extends StatelessWidget {
  final bool enabled;
  final String title;
  final VoidCallback onTap;

  const _GooglePayPlaceholder({
    required this.enabled,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E1810).withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1E1810)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool dark;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = dark ? Colors.black : Colors.white;
    final titleColor = dark ? Colors.white : const Color(0xFF1E1810);
    final subtitleColor = dark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF3A3028).withValues(alpha: 0.68);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: dark ? null : Border.all(color: const Color(0xFF1E1810).withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: titleColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final Color productColor;

  const _SuccessCard({required this.productColor});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            productColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: productColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: productColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: productColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reportProductCheckoutSuccessTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1810),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.reportProductCheckoutSuccessBody,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: const Color(0xFF3A3028).withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
