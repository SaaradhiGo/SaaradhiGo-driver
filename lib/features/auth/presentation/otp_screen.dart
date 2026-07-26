import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/push/push_service.dart';
import '../../../core/widgets/common.dart';
import 'auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();

  /// The server issues at most 5 OTPs an hour and 2 a minute, so the resend
  /// timer is not decoration — tapping earlier just earns a 429.
  static const _resendSeconds = 45;
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    final otp = _controller.text.trim();
    if (otp.length < 4) return;
    FocusScope.of(context).unfocus();

    // Hand the FCM token over with the login so dispatch can reach this
    // device from the first ride onward, rather than after the next restart.
    final deviceToken = await PushService.instance.refreshToken();

    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(otp, deviceToken: deviceToken);

    if (!mounted) return;
    if (ok) {
      context.go(Routes.home);
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) showErrorSnack(context, error);
      _controller.clear();
    }
  }

  Future<void> _resend() async {
    final phone = ref.read(authControllerProvider).otpRequestedFor;
    if (phone == null) return;
    final ok = await ref.read(authControllerProvider.notifier).requestOtp(phone);
    if (!mounted) return;
    if (ok) {
      _startTimer();
      showInfoSnack(context, 'OTP sent again');
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) showErrorSnack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final phone = auth.otpRequestedFor ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(Routes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the code',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to $phone',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                ),
                onChanged: (value) {
                  // Auto-submit on the sixth digit: one less tap at a kerb.
                  if (value.length == 6) _verify();
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: auth.isBusy ? null : _verify,
                child: auth.isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Verify and sign in'),
              ),
              const SizedBox(height: 16),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Resend code in ${_secondsLeft}s',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : TextButton(
                        onPressed: auth.isBusy ? null : _resend,
                        child: const Text('Resend code'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
