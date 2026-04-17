import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/features/profile/domain/entities/profile_shipping_address_entity.dart';
import 'package:stitch_diag_demo/features/profile/presentation/providers/profile_address_provider.dart';

const _kAddressPageBg = Color(0xFFF4F1EB);
const _kAddressCardBg = Colors.white;
const _kAddressPrimary = Color(0xFF2D6A4F);
const _kAddressTextPrimary = Color(0xFF1E1810);
const _kAddressTextSecondary = Color(0xFF7A6F63);
const _kAddressDivider = Color(0xFFF0EDE5);
final _addressCodeRegExp = RegExp(r'^[A-Za-z0-9_-]+$');
final _addressPhoneDigitsRegExp = RegExp(r'^[0-9]{6,20}$');
final _addressCodeInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[A-Za-z0-9_-]'),
);
final _addressPhoneInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9+\-\s()]'),
);

class ShippingAddressPage extends ConsumerWidget {
  const ShippingAddressPage({super.key});

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshAddresses(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profileAddressesProvider.notifier).refresh();
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showErrorSnackBar(context, context.l10n.profileAddressLoadFailed);
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    ProfileShippingAddressEntity? initial,
    required bool forceDefault,
  }) async {
    var editorInitial = initial;
    if (initial != null && initial.id.isNotEmpty) {
      try {
        editorInitial = await ref
            .read(profileAddressesProvider.notifier)
            .loadAddressDetail(initial.id);
      } on Object {
        if (context.mounted) {
          _showErrorSnackBar(context, context.l10n.profileAddressLoadFailed);
        }
      }
    }
    if (!context.mounted) {
      return;
    }

    final result = await showModalBottomSheet<ProfileShippingAddressEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddressEditorSheet(
          initial: editorInitial,
          forceDefault: forceDefault,
        );
      },
    );
    if (result == null) {
      return;
    }
    try {
      await ref.read(profileAddressesProvider.notifier).upsertAddress(result);
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showErrorSnackBar(context, context.l10n.profileAddressSaveFailed);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProfileShippingAddressEntity address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.profileAddressDeleteTitle),
          content: Text(context.l10n.profileAddressDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.profileAddressDeleteAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref
          .read(profileAddressesProvider.notifier)
          .deleteAddress(address.id);
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showErrorSnackBar(context, context.l10n.profileAddressDeleteFailed);
    }
  }

  Future<void> _setDefaultAddress(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(profileAddressesProvider.notifier).setDefaultAddress(id);
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showErrorSnackBar(context, context.l10n.profileAddressDefaultFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(profileAddressesProvider);
    final addresses = addressesAsync.asData?.value ?? const [];

    return Scaffold(
      backgroundColor: _kAddressPageBg,
      appBar: AppBar(
        backgroundColor: _kAddressPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.profileAddressTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kAddressTextPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAddressPrimary,
        foregroundColor: Colors.white,
        onPressed: () =>
            _openEditor(context, ref, forceDefault: addresses.isEmpty),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(context.l10n.profileAddressAdd),
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _refreshAddresses(context, ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  _AddressEmptyState(
                    onAdd: () => _openEditor(context, ref, forceDefault: true),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refreshAddresses(context, ref),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _AddressCard(
                  address: address,
                  onEdit: () => _openEditor(
                    context,
                    ref,
                    initial: address,
                    forceDefault: addresses.length == 1 && address.isDefault,
                  ),
                  onDelete: () => _confirmDelete(context, ref, address),
                  onSetDefault: address.isDefault
                      ? null
                      : () => _setDefaultAddress(context, ref, address.id),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.profileAddressLoadFailed,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _kAddressTextSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _refreshAddresses(context, ref),
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddressEmptyState extends StatelessWidget {
  const _AddressEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: _kAddressCardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kAddressPrimary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _kAddressPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: _kAddressPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.profileAddressEmptyTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kAddressTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.profileAddressEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: _kAddressTextSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAddressPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(context.l10n.profileAddressAdd),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final ProfileShippingAddressEntity address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAddressCardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kAddressPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      address.receiverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kAddressTextPrimary,
                      ),
                    ),
                    Text(
                      address.receiverMobile,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kAddressTextSecondary,
                      ),
                    ),
                    if (address.isDefault)
                      _AddressBadge(
                        label: context.l10n.profileAddressDefault,
                        backgroundColor: _kAddressPrimary.withValues(
                          alpha: 0.10,
                        ),
                        textColor: _kAddressPrimary,
                      ),
                    if ((address.streetName ?? '').trim().isNotEmpty)
                      _AddressBadge(
                        label: address.streetName!.trim(),
                        backgroundColor: const Color(
                          0xFFC9A84C,
                        ).withValues(alpha: 0.12),
                        textColor: const Color(0xFF8A6F3C),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.fullAddress,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: _kAddressTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _kAddressDivider),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onSetDefault != null)
                OutlinedButton(
                  onPressed: onSetDefault,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAddressPrimary,
                    side: BorderSide(
                      color: _kAddressPrimary.withValues(alpha: 0.28),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(context.l10n.profileAddressSetDefault),
                ),
              OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kAddressTextPrimary,
                  side: const BorderSide(color: _kAddressDivider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.l10n.profileAddressEdit),
              ),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB04C37),
                ),
                child: Text(context.l10n.profileAddressDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressBadge extends StatelessWidget {
  const _AddressBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({this.initial, required this.forceDefault});

  final ProfileShippingAddressEntity? initial;
  final bool forceDefault;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _receiverController;
  late final TextEditingController _phoneController;
  late final TextEditingController _provinceNameController;
  late final TextEditingController _provinceCodeController;
  late final TextEditingController _cityNameController;
  late final TextEditingController _cityCodeController;
  late final TextEditingController _districtNameController;
  late final TextEditingController _districtCodeController;
  late final TextEditingController _streetNameController;
  late final TextEditingController _streetCodeController;
  late final TextEditingController _detailController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _receiverController = TextEditingController(
      text: initial?.receiverName ?? '',
    );
    _phoneController = TextEditingController(
      text: initial?.receiverMobile ?? '',
    );
    _provinceNameController = TextEditingController(
      text: initial?.provinceName ?? '',
    );
    _provinceCodeController = TextEditingController(
      text: initial?.provinceCode ?? '',
    );
    _cityNameController = TextEditingController(text: initial?.cityName ?? '');
    _cityCodeController = TextEditingController(text: initial?.cityCode ?? '');
    _districtNameController = TextEditingController(
      text: initial?.districtName ?? '',
    );
    _districtCodeController = TextEditingController(
      text: initial?.districtCode ?? '',
    );
    _streetNameController = TextEditingController(
      text: initial?.streetName ?? '',
    );
    _streetCodeController = TextEditingController(
      text: initial?.streetCode ?? '',
    );
    _detailController = TextEditingController(
      text: initial?.detailAddress ?? '',
    );
    _isDefault = initial?.isDefault ?? widget.forceDefault;
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _phoneController.dispose();
    _provinceNameController.dispose();
    _provinceCodeController.dispose();
    _cityNameController.dispose();
    _cityCodeController.dispose();
    _districtNameController.dispose();
    _districtCodeController.dispose();
    _streetNameController.dispose();
    _streetCodeController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ProfileShippingAddressEntity(
        id: widget.initial?.id ?? '',
        receiverName: _receiverController.text.trim(),
        receiverMobile: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        provinceCode: _provinceCodeController.text.trim(),
        provinceName: _provinceNameController.text.trim(),
        cityCode: _cityCodeController.text.trim(),
        cityName: _cityNameController.text.trim(),
        districtCode: _districtCodeController.text.trim(),
        districtName: _districtNameController.text.trim(),
        streetCode: _streetCodeController.text.trim(),
        streetName: _streetNameController.text.trim(),
        detailAddress: _detailController.text.trim(),
        isDefault: widget.forceDefault ? true : _isDefault,
      ),
    );
  }

  String? _validateRequiredText(String? value, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (!_addressPhoneDigitsRegExp.hasMatch(normalized)) {
      return context.l10n.profileAddressValidationPhone;
    }
    return null;
  }

  String? _validateCode(String? value, String emptyError) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return emptyError;
    }
    if (!_addressCodeRegExp.hasMatch(trimmed)) {
      return context.l10n.profileAddressValidationCodeFormat;
    }
    return null;
  }

  String? _validateStreetName(String? value) {
    final name = value?.trim() ?? '';
    final code = _streetCodeController.text.trim();
    if (name.isEmpty && code.isEmpty) {
      return null;
    }
    if (name.isEmpty || code.isEmpty) {
      return context.l10n.profileAddressValidationStreetPair;
    }
    return null;
  }

  String? _validateStreetCode(String? value) {
    final code = value?.trim() ?? '';
    final name = _streetNameController.text.trim();
    if (name.isEmpty && code.isEmpty) {
      return null;
    }
    if (name.isEmpty || code.isEmpty) {
      return context.l10n.profileAddressValidationStreetPair;
    }
    if (!_addressCodeRegExp.hasMatch(code)) {
      return context.l10n.profileAddressValidationCodeFormat;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.initial == null
                              ? context.l10n.profileAddressFormAddTitle
                              : context.l10n.profileAddressFormEditTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kAddressTextPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AddressField(
                    controller: _receiverController,
                    label: context.l10n.profileAddressReceiver,
                    validator: (value) => _validateRequiredText(
                      value,
                      context.l10n.profileAddressValidationReceiver,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AddressField(
                    controller: _phoneController,
                    label: context.l10n.profileAddressPhone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_addressPhoneInputFormatter],
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 12),
                  _AddressFieldRow(
                    left: _AddressField(
                      controller: _provinceNameController,
                      label: context.l10n.profileAddressProvinceName,
                      validator: (value) => _validateRequiredText(
                        value,
                        context.l10n.profileAddressValidationProvinceName,
                      ),
                    ),
                    right: _AddressField(
                      controller: _provinceCodeController,
                      label: context.l10n.profileAddressProvinceCode,
                      inputFormatters: [_addressCodeInputFormatter],
                      validator: (value) => _validateCode(
                        value,
                        context.l10n.profileAddressValidationProvinceCode,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AddressFieldRow(
                    left: _AddressField(
                      controller: _cityNameController,
                      label: context.l10n.profileAddressCityName,
                      validator: (value) => _validateRequiredText(
                        value,
                        context.l10n.profileAddressValidationCityName,
                      ),
                    ),
                    right: _AddressField(
                      controller: _cityCodeController,
                      label: context.l10n.profileAddressCityCode,
                      inputFormatters: [_addressCodeInputFormatter],
                      validator: (value) => _validateCode(
                        value,
                        context.l10n.profileAddressValidationCityCode,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AddressFieldRow(
                    left: _AddressField(
                      controller: _districtNameController,
                      label: context.l10n.profileAddressDistrictName,
                      validator: (value) => _validateRequiredText(
                        value,
                        context.l10n.profileAddressValidationDistrictName,
                      ),
                    ),
                    right: _AddressField(
                      controller: _districtCodeController,
                      label: context.l10n.profileAddressDistrictCode,
                      inputFormatters: [_addressCodeInputFormatter],
                      validator: (value) => _validateCode(
                        value,
                        context.l10n.profileAddressValidationDistrictCode,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AddressFieldRow(
                    left: _AddressField(
                      controller: _streetNameController,
                      label: context.l10n.profileAddressStreetName,
                      validator: _validateStreetName,
                    ),
                    right: _AddressField(
                      controller: _streetCodeController,
                      label: context.l10n.profileAddressStreetCode,
                      inputFormatters: [_addressCodeInputFormatter],
                      validator: _validateStreetCode,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AddressField(
                    controller: _detailController,
                    label: context.l10n.profileAddressDetail,
                    maxLines: 3,
                    validator: (value) => _validateRequiredText(
                      value,
                      context.l10n.profileAddressValidationDetail,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: widget.forceDefault ? true : _isDefault,
                    activeThumbColor: _kAddressPrimary,
                    activeTrackColor: _kAddressPrimary.withValues(alpha: 0.32),
                    contentPadding: EdgeInsets.zero,
                    onChanged: widget.forceDefault
                        ? null
                        : (value) => setState(() => _isDefault = value),
                    title: Text(
                      context.l10n.profileAddressDefaultToggle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kAddressTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kAddressPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(context.l10n.commonSave),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressFieldRow extends StatelessWidget {
  const _AddressFieldRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F5F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kAddressPrimary),
        ),
      ),
    );
  }
}
