// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Future<String?> showAliyunCaptchaWebDialog({
  required BuildContext context,
  required Uri url,
  required String challengeId,
  required String title,
  required String cancelLabel,
  required String loadingText,
  required String readyText,
  required String failedText,
  required String pageLoadFailedText,
  required String initFailedText,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AliyunCaptchaWebDialog(
      url: url,
      challengeId: challengeId,
      title: title,
      cancelLabel: cancelLabel,
      loadingText: loadingText,
      readyText: readyText,
      failedText: failedText,
      pageLoadFailedText: pageLoadFailedText,
      initFailedText: initFailedText,
    ),
  );
}

class _AliyunCaptchaWebDialog extends StatefulWidget {
  const _AliyunCaptchaWebDialog({
    required this.url,
    required this.challengeId,
    required this.title,
    required this.cancelLabel,
    required this.loadingText,
    required this.readyText,
    required this.failedText,
    required this.pageLoadFailedText,
    required this.initFailedText,
  });

  final Uri url;
  final String challengeId;
  final String title;
  final String cancelLabel;
  final String loadingText;
  final String readyText;
  final String failedText;
  final String pageLoadFailedText;
  final String initFailedText;

  @override
  State<_AliyunCaptchaWebDialog> createState() => _AliyunCaptchaWebDialogState();
}

class _AliyunCaptchaWebDialogState extends State<_AliyunCaptchaWebDialog> {
  late final String _viewType;
  late final html.IFrameElement _iframeElement;
  StreamSubscription<html.MessageEvent>? _messageSubscription;
  StreamSubscription<html.Event>? _iframeErrorSubscription;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _statusText = widget.loadingText;
    _viewType =
        'aliyun-captcha-web-${widget.challengeId}-${DateTime.now().microsecondsSinceEpoch}';
    _iframeElement = html.IFrameElement()
      ..src = widget.url.toString()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'clipboard-read; clipboard-write'
      ..allowFullscreen = true;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId, {Object? params}) => _iframeElement,
    );

    _iframeErrorSubscription = _iframeElement.onError.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() => _statusText = widget.pageLoadFailedText);
    });

    _messageSubscription = html.window.onMessage.listen(_handleMessage);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _iframeErrorSubscription?.cancel();
    _iframeElement.remove();
    super.dispose();
  }

  void _handleMessage(html.MessageEvent event) {
    if (event.origin != widget.url.origin) {
      return;
    }

    final payload = _AliyunCaptchaWebBridgePayload.tryParse(event.data);
    if (payload == null) {
      return;
    }
    if (payload.challengeId != null && payload.challengeId != widget.challengeId) {
      return;
    }

    switch (payload.type) {
      case 'ready':
        if (!mounted) {
          return;
        }
        setState(() => _statusText = widget.readyText);
        return;
      case 'success':
        final captchaVerifyParam = payload.captchaVerifyParam;
        if (!mounted) {
          return;
        }
        if (captchaVerifyParam == null || captchaVerifyParam.isEmpty) {
          setState(() => _statusText = widget.initFailedText);
          return;
        }
        Navigator.of(context).pop(captchaVerifyParam);
        return;
      case 'fail':
        if (!mounted) {
          return;
        }
        setState(() => _statusText = widget.failedText);
        return;
      case 'error':
      default:
        if (!mounted) {
          return;
        }
        setState(() => _statusText = payload.message ?? widget.initFailedText);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.white,
                    child: HtmlElementView(viewType: _viewType),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(widget.cancelLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AliyunCaptchaWebBridgePayload {
  const _AliyunCaptchaWebBridgePayload({
    required this.type,
    this.challengeId,
    this.captchaVerifyParam,
    this.message,
  });

  final String type;
  final String? challengeId;
  final String? captchaVerifyParam;
  final String? message;

  static _AliyunCaptchaWebBridgePayload? tryParse(Object? raw) {
    final map = _asStringMap(raw);
    if (map == null) {
      return null;
    }

    final type = _trimmedString(map['type']);
    if (type == null) {
      return null;
    }

    return _AliyunCaptchaWebBridgePayload(
      type: type,
      challengeId: _trimmedString(map['challengeId']),
      captchaVerifyParam: _trimmedString(map['captchaVerifyParam']),
      message: _trimmedString(map['message']),
    );
  }

  static Map<String, dynamic>? _asStringMap(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        return null;
      }
      return null;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }

    try {
      final dartValue = (raw as JSAny).dartify();
      if (dartValue is Map) {
        return dartValue.map((key, value) => MapEntry(key.toString(), value));
      }
      if (dartValue is String) {
        return _asStringMap(dartValue);
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}

String? _trimmedString(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}
