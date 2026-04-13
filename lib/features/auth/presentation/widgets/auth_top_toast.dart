import 'dart:async';

import 'package:flutter/material.dart';

enum AuthTopToastKind { success, error }

class AuthTopToastController {
  OverlayEntry? _entry;
  Timer? _timer;

  void show(
    BuildContext context,
    String message, {
    AuthTopToastKind kind = AuthTopToastKind.error,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    hide();
    final entry = OverlayEntry(
      builder: (_) => AuthTopToast(message: message, kind: kind),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, hide);
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  void dispose() {
    hide();
  }
}

class AuthTopToast extends StatefulWidget {
  const AuthTopToast({super.key, required this.message, required this.kind});

  final String message;
  final AuthTopToastKind kind;

  @override
  State<AuthTopToast> createState() => _AuthTopToastState();
}

class _AuthTopToastState extends State<AuthTopToast> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top + 12;
    final theme = _themeFor(widget.kind);

    return Positioned(
      top: topInset,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, -0.85),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                key: ValueKey('auth_top_toast_${widget.kind.name}'),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                    child: Row(
                      children: [
                        Icon(theme.icon, size: 18, color: theme.accentColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textColor,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AuthTopToastTheme _themeFor(AuthTopToastKind kind) {
    return switch (kind) {
      AuthTopToastKind.error => const _AuthTopToastTheme(
        backgroundColor: Color(0xFFFFF8EC),
        accentColor: Color(0xFFC9A84C),
        textColor: Color(0xFF3A3028),
        icon: Icons.info_outline,
      ),
      AuthTopToastKind.success => const _AuthTopToastTheme(
        backgroundColor: Color(0xFFEEF7F1),
        accentColor: Color(0xFF2D6A4F),
        textColor: Color(0xFF1E1810),
        icon: Icons.check_circle_outline,
      ),
    };
  }
}

class _AuthTopToastTheme {
  const _AuthTopToastTheme({
    required this.backgroundColor,
    required this.accentColor,
    required this.textColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color accentColor;
  final Color textColor;
  final IconData icon;
}
