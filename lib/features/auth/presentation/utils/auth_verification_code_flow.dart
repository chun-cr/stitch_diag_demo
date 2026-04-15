import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_target.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/captcha_resolver_provider.dart';

class VerificationCodeFlowState {
  bool codeSending = false;
  bool codeCountingDown = false;
  int codeCountdown = 60;
  Timer? countdownTimer;
  bool verificationCodeSent = false;
  String? codeTargetValue;
  String? codeTargetCountryCode;
  String? challengeId;
  DateTime? challengeExpireAt;
  DateTime? verificationCodeExpireAt;
  String? maskedReceiver;
  String? captchaProvider;
  Map<String, dynamic>? captchaInitPayload;
  bool captchaVerified = false;

  void dispose() {
    countdownTimer?.cancel();
    countdownTimer = null;
  }
}

Object? authResponseCode(dynamic responseData) {
  if (responseData is! Map<String, dynamic>) {
    return null;
  }
  return responseData['code'];
}

String? authResponseMessage(dynamic responseData) {
  if (responseData is! Map<String, dynamic>) {
    return null;
  }
  final message = responseData['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }
  return null;
}

VerificationCodeSendEntity? verificationCodeSendEntityFromEnvelope(
  dynamic responseData, {
  String? fallbackMaskedReceiver,
}) {
  if (responseData is! Map<String, dynamic>) {
    return null;
  }
  final data = responseData['data'];
  if (data is! Map<String, dynamic>) {
    return null;
  }
  final resendAtRaw = data['resendAt'] as String?;
  final expireAtRaw = data['expireAt'] as String?;
  return VerificationCodeSendEntity(
    channel: (data['channel'] as String?) ?? 'PHONE',
    maskedReceiver:
        (data['maskedReceiver'] as String?) ?? (fallbackMaskedReceiver ?? ''),
    expireAt: expireAtRaw == null ? null : DateTime.tryParse(expireAtRaw),
    resendAt: resendAtRaw == null ? null : DateTime.tryParse(resendAtRaw),
  );
}

mixin VerificationCodeFlowMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  VerificationCodeFlowState get verificationCodeFlow;
  TextEditingController get verificationCodeController;
  String get currentVerificationAccountValue;
  String? get currentVerificationCountryCode;
  VerificationCodeTarget get currentVerificationCodeTarget;
  VerificationCodeScene get verificationCodeScene;
  String get verificationCodeSuccessMessageText;
  void showVerificationError(String message);
  void showVerificationSuccess(String message);

  void resetVerificationCodeState({
    bool clearCode = true,
    bool clearChallenge = true,
  }) {
    verificationCodeFlow.countdownTimer?.cancel();
    verificationCodeFlow.countdownTimer = null;
    verificationCodeFlow.codeSending = false;
    verificationCodeFlow.codeCountingDown = false;
    verificationCodeFlow.codeCountdown = 60;
    verificationCodeFlow.verificationCodeSent = false;
    verificationCodeFlow.codeTargetValue = null;
    verificationCodeFlow.codeTargetCountryCode = null;
    verificationCodeFlow.verificationCodeExpireAt = null;
    verificationCodeFlow.maskedReceiver = null;
    if (clearChallenge) {
      verificationCodeFlow.challengeId = null;
      verificationCodeFlow.challengeExpireAt = null;
      verificationCodeFlow.captchaProvider = null;
      verificationCodeFlow.captchaInitPayload = null;
      verificationCodeFlow.captchaVerified = false;
    }
    if (clearCode) {
      verificationCodeController.clear();
    }
  }

  bool get shouldRefreshVerificationChallenge {
    final challengeId = verificationCodeFlow.challengeId;
    final expireAt = verificationCodeFlow.challengeExpireAt;
    if (challengeId == null || challengeId.isEmpty || expireAt == null) {
      return true;
    }
    return !expireAt.isAfter(DateTime.now());
  }

  bool get isVerificationCodeExpired {
    if (!verificationCodeFlow.verificationCodeSent) {
      return false;
    }
    final expireAt =
        verificationCodeFlow.verificationCodeExpireAt ??
        verificationCodeFlow.challengeExpireAt;
    if (expireAt == null) {
      return false;
    }
    return !expireAt.isAfter(DateTime.now());
  }

  bool get hasActiveVerificationCodeSubmission {
    final challengeId = verificationCodeFlow.challengeId;
    final targetValue = verificationCodeFlow.codeTargetValue;
    if (challengeId == null || challengeId.isEmpty) {
      return false;
    }
    if (!verificationCodeFlow.verificationCodeSent || targetValue == null) {
      return false;
    }
    if (currentVerificationAccountValue != targetValue) {
      return false;
    }
    if (currentVerificationCountryCode !=
        verificationCodeFlow.codeTargetCountryCode) {
      return false;
    }
    return !isVerificationCodeExpired;
  }

  void resetVerificationStateIfTargetChanged(String value) {
    final targetValue = verificationCodeFlow.codeTargetValue;
    if (targetValue == null) {
      return;
    }
    if (value.trim() != targetValue) {
      setState(() {
        resetVerificationCodeState();
      });
    }
  }

  Future<bool> ensureCaptchaVerifiedIfNeeded(AuthRepository repository) async {
    final challengeId = verificationCodeFlow.challengeId;
    final provider = verificationCodeFlow.captchaProvider;
    final l10n = context.l10n;
    if (challengeId == null || challengeId.isEmpty) {
      return false;
    }
    if (provider == null ||
        provider.isEmpty ||
        verificationCodeFlow.captchaVerified) {
      return true;
    }

    final payload = await ref
        .read(captchaResolverProvider)
        .resolve(
          context: context,
          challengeId: challengeId,
          provider: provider,
          initPayload: verificationCodeFlow.captchaInitPayload,
        );
    if (!mounted || payload == null) {
      return false;
    }

    try {
      final verified = await repository.verifyVerificationCodeCaptcha(
        challengeId: challengeId,
        captchaProvider: provider,
        captchaPayload: payload,
      );
      if (!mounted) {
        return false;
      }
      if (!verified) {
        showVerificationError(l10n.authCaptchaFailed);
        return false;
      }
      setState(() {
        verificationCodeFlow.captchaVerified = true;
      });
      return true;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final code = authResponseCode(responseData);
      if (mounted && (code == 11119 || code == 11121)) {
        setState(() {
          resetVerificationCodeState(clearCode: false);
        });
      }
      showVerificationError(
        authResponseMessage(responseData) ?? l10n.authCaptchaFailed,
      );
      return false;
    } catch (_) {
      showVerificationError(l10n.authCaptchaFailed);
      return false;
    }
  }

  Future<void> sendVerificationCode() async {
    final l10n = context.l10n;
    if (verificationCodeFlow.codeSending ||
        verificationCodeFlow.codeCountingDown) {
      return;
    }

    setState(() {
      verificationCodeFlow.codeSending = true;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      if (shouldRefreshVerificationChallenge) {
        final challenge = await repository.createVerificationCodeChallenge(
          scene: verificationCodeScene,
          target: currentVerificationCodeTarget,
        );
        verificationCodeFlow.challengeId = challenge.challengeId;
        verificationCodeFlow.challengeExpireAt = challenge.expireAt;
        verificationCodeFlow.codeTargetValue = currentVerificationAccountValue;
        verificationCodeFlow.codeTargetCountryCode =
            currentVerificationCountryCode;
        verificationCodeFlow.captchaProvider = challenge.captchaProvider;
        verificationCodeFlow.captchaInitPayload = challenge.captchaPayload;
        verificationCodeFlow.captchaVerified = !challenge.captchaRequired;
      }

      final captchaVerified = await ensureCaptchaVerifiedIfNeeded(repository);
      if (!captchaVerified) {
        if (mounted) {
          setState(() {
            verificationCodeFlow.codeSending = false;
          });
        }
        return;
      }

      final sendResult = await repository.sendCode(
        challengeId: verificationCodeFlow.challengeId!,
      );
      showVerificationSuccess(verificationCodeSuccessMessageText);
      if (!mounted) {
        return;
      }
      startVerificationCodeCountdown(sendResult);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final serverMessage = authResponseMessage(responseData);
      if (mounted) {
        setState(() {
          verificationCodeFlow.codeSending = false;
        });
      }
      final code = authResponseCode(responseData);
      if (code == 11119 || code == 11121) {
        if (mounted) {
          setState(() {
            resetVerificationCodeState();
          });
        }
      }
      if (code == 11122 || code == 11123) {
        if (mounted) {
          setState(() {
            verificationCodeFlow.captchaVerified = false;
          });
        }
      }
      if (code == 11120) {
        final sendResult = verificationCodeSendEntityFromEnvelope(
          responseData,
          fallbackMaskedReceiver: verificationCodeFlow.maskedReceiver,
        );
        if (sendResult != null && mounted) {
          startVerificationCodeCountdown(sendResult);
        }
      }
      showVerificationError(serverMessage ?? l10n.authSendCodeFailed);
    } catch (_) {
      if (mounted) {
        setState(() {
          verificationCodeFlow.codeSending = false;
        });
      }
      showVerificationError(l10n.authSendCodeFailed);
    }
  }

  void startVerificationCodeCountdown(VerificationCodeSendEntity sendResult) {
    verificationCodeFlow.countdownTimer?.cancel();
    verificationCodeFlow.countdownTimer = null;

    final seconds = _secondsUntil(sendResult.resendAt);
    setState(() {
      verificationCodeFlow.codeSending = false;
      verificationCodeFlow.codeCountingDown = seconds > 0;
      verificationCodeFlow.codeCountdown = seconds > 0 ? seconds : 60;
      verificationCodeFlow.verificationCodeSent = true;
      verificationCodeFlow.codeTargetValue = currentVerificationAccountValue;
      verificationCodeFlow.codeTargetCountryCode =
          currentVerificationCountryCode;
      verificationCodeFlow.verificationCodeExpireAt =
          sendResult.expireAt ?? verificationCodeFlow.challengeExpireAt;
      verificationCodeFlow.maskedReceiver = sendResult.maskedReceiver;
    });

    if (seconds <= 0) {
      return;
    }

    verificationCodeFlow.countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          verificationCodeFlow.countdownTimer = null;
          return;
        }
        setState(() {
          verificationCodeFlow.codeCountdown--;
        });
        if (verificationCodeFlow.codeCountdown <= 0) {
          timer.cancel();
          setState(() {
            verificationCodeFlow.countdownTimer = null;
            verificationCodeFlow.codeCountingDown = false;
            verificationCodeFlow.codeCountdown = 60;
          });
        }
      },
    );
  }

  int _secondsUntil(DateTime? target) {
    if (target == null) {
      return 60;
    }
    final diff = target.difference(DateTime.now()).inSeconds;
    return diff <= 0 ? 0 : diff;
  }
}
