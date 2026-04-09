import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class CaptchaResolver {
  Future<Map<String, String>?> resolve({
    required BuildContext context,
    required String provider,
    Map<String, dynamic>? initPayload,
  });
}

final captchaResolverProvider = Provider<CaptchaResolver>((ref) {
  return const ManualCaptchaResolver();
});

class ManualCaptchaResolver implements CaptchaResolver {
  const ManualCaptchaResolver();

  @override
  Future<Map<String, String>?> resolve({
    required BuildContext context,
    required String provider,
    Map<String, dynamic>? initPayload,
  }) async {
    final controller = TextEditingController(text: '{}');
    try {
      return await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          String? errorText;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('人机验证'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('需要先完成 $provider 验证。请粘贴 provider 返回的 JSON 结果后继续。'),
                        if (initPayload != null && initPayload.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            '初始化参数',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F4EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SelectableText(_prettyJson(initPayload)),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Text(
                          '验证结果 JSON',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          key: const ValueKey('captcha_payload_input'),
                          controller: controller,
                          minLines: 4,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: '{"ticket":"..."}',
                            errorText: errorText,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    key: const ValueKey('captcha_dialog_cancel'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                    ),
                  ),
                  FilledButton(
                    key: const ValueKey('captcha_dialog_confirm'),
                    onPressed: () {
                      final payload = _parsePayload(controller.text);
                      if (payload == null) {
                        setState(() {
                          errorText = '请输入合法的 JSON 对象';
                        });
                        return;
                      }
                      Navigator.of(dialogContext).pop(payload);
                    },
                    child: const Text('继续'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  static String _prettyJson(Map<String, dynamic> payload) {
    try {
      return const JsonEncoder.withIndent('  ').convert(payload);
    } catch (_) {
      return payload.toString();
    }
  }

  static Map<String, String>? _parsePayload(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(input);
    if (decoded is! Map) {
      return null;
    }

    final payload = <String, String>{};
    for (final entry in decoded.entries) {
      final key = entry.key?.toString().trim() ?? '';
      if (key.isEmpty || entry.value == null) {
        return null;
      }
      payload[key] = entry.value.toString();
    }
    return payload;
  }
}
