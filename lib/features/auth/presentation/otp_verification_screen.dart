import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons.dart';
import 'providers/auth_notifier.dart';
import 'providers/auth_state.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Timer? _timer;
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(widget.phoneNumber, _otpController.text.trim());
    }
  }

  void _resend() {
    if (_canResend) {
      ref.read(authNotifierProvider.notifier).requestOtp(widget.phoneNumber);
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading =
        authState is AuthVerifyingOtp || authState is AuthRequestingOtp;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter the code',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We sent a 6-digit code to ${maskedPhone(widget.phoneNumber)}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: AppTypography.dataMono.copyWith(
                    fontSize: SgText.size(24),
                    letterSpacing: 14,
                  ),
                  decoration: const InputDecoration(counterText: ''),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter the code we sent';
                    }
                    if (value.length != 6 ||
                        !RegExp(r'^\d+$').hasMatch(value)) {
                      return 'The code is 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  text: 'Continue',
                  isLoading: isLoading,
                  onPressed: isLoading ? () {} : _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: _canResend && !isLoading ? _resend : null,
                  child: Text(
                    _canResend
                        ? 'Send a new code'
                        : 'New code in ${_countdown}s',
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _canResend
                          ? AppColors.onBackground
                          : AppColors.onSurfaceVariant,
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

/// "+91 ••••• •5176": enough to recognise the number, not to read it out.
String maskedPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return phone;
  final last = digits.substring(digits.length - 4);
  final prefix = phone.startsWith('+') && digits.length > 10
      ? '+${digits.substring(0, digits.length - 10)} '
      : '';
  return '$prefix••••• •$last';
}
