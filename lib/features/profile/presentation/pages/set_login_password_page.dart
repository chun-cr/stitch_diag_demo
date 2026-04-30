// 个人中心模块页面：`SetLoginPasswordPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/security/login_password_store.dart';

const _kPasswordPageBg = Color(0xFFF4F1EB);
const _kPasswordCardBg = Colors.white;
const _kPasswordPrimary = Color(0xFF2D6A4F);
const _kPasswordTextPrimary = Color(0xFF1E1810);
const _kPasswordTextSecondary = Color(0xFF7A6F63);

class SetLoginPasswordPage extends StatefulWidget {
  const SetLoginPasswordPage({super.key});

  @override
  State<SetLoginPasswordPage> createState() => _SetLoginPasswordPageState();
}

class _SetLoginPasswordPageState extends State<SetLoginPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    await getIt<LoginPasswordStore>().setHasLoginPassword(true);
    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPasswordPageBg,
      appBar: AppBar(
        backgroundColor: _kPasswordPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.setLoginPasswordTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPasswordTextPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            color: _kPasswordCardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPasswordPrimary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.setLoginPasswordSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: _kPasswordTextSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _PasswordField(
                  controller: _passwordCtrl,
                  label: context.l10n.authPasswordLabel,
                  hintText: context.l10n.registerPasswordHint,
                  obscureText: _obscurePassword,
                  onToggle: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return context.l10n.authPasswordMin8;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _confirmPasswordCtrl,
                  label: context.l10n.authConfirmPasswordLabel,
                  hintText: context.l10n.authConfirmPasswordHint,
                  obscureText: _obscureConfirmPassword,
                  onToggle: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  validator: (value) {
                    if (value != _passwordCtrl.text) {
                      return context.l10n.authPasswordMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPasswordPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n.setLoginPasswordAction,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.obscureText,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kPasswordTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: _kPasswordTextPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA09080)),
            filled: true,
            fillColor: const Color(0xFFF9F7F2),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Color(0xFFA09080),
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: const Color(0xFFA09080),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _kPasswordPrimary.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _kPasswordPrimary.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _kPasswordPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
