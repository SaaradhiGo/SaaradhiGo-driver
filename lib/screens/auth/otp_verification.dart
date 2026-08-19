import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../navigation/route_names.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  
  int _timeLeft = 45;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDigitInput(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-verify when all 6 digits are entered
        _onVerifyPressed();
      }
    }
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  /// Collect all 6 OTP digits into a single string
  String _getOtpString() {
    return _controllers.map((c) => c.text).join();
  }

  /// Verify OTP with the real backend API
  Future<void> _onVerifyPressed() async {
    final otp = _getOtpString();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter all 6 digits',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onErrorContainer),
          ),
          backgroundColor: AppColors.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    final response = await AuthService.verifyOtp(widget.phoneNumber, otp);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (response.success) {
      final user = response.data?['user'] as Map<String, dynamic>?;
      final isUpdated = user?['is_updated'] ?? true;

      if (!isUpdated) {
        // Navigate to onboarding personal details screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.onboardingPersonal,
          (route) => false,
        );
      } else {
        // Navigate to dashboard, clearing entire back stack
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.dashboard,
          (route) => false,
        );
      }
    } else {
      // Clear OTP fields on failure
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? 'Invalid OTP. Please try again.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onErrorContainer),
          ),
          backgroundColor: AppColors.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// Resend OTP when timer expires
  Future<void> _onResendOtp() async {
    if (_timeLeft > 0) return;

    final response = await AuthService.sendOtp(widget.phoneNumber);

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _timeLeft = 45;
      });
      _timer?.cancel();
      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP sent successfully',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onPrimaryContainer),
          ),
          backgroundColor: AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? 'Failed to resend OTP',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onErrorContainer),
          ),
          backgroundColor: AppColors.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.stackLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Verify Account',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              RichText(
                text: TextSpan(
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                    TextSpan(
                      text: '+91 ${widget.phoneNumber}',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg * 1.5),
              
              // OTP Input Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 56, // matching w-14 assuming 4px unit roughly, actually 56px
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyEvent(event, index),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        style: AppTypography.headlineMd.copyWith(
                          color: AppColors.onBackground,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary, // primary gold
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onDigitInput(value, index),
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: AppSpacing.stackLg),
              
              // Resend & Change Number Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _timeLeft == 0 ? _onResendOtp : null,
                    child: Row(
                      children: [
                        Text(
                          _timeLeft > 0 ? 'Resend code in ' : 'Resend code',
                          style: AppTypography.bodyMd.copyWith(
                            color: _timeLeft == 0 ? AppColors.primary : AppColors.onSurfaceVariant,
                            fontWeight: _timeLeft == 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (_timeLeft > 0)
                          Text(
                            '00:${_timeLeft.toString().padLeft(2, '0')}',
                            style: AppTypography.dataMono.copyWith(
                              color: AppColors.primaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Change number logic
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Change Number',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Primary Action Button
              Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryContainer,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _isVerifying ? null : _onVerifyPressed,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isVerifying)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onPrimary,
                            ),
                          )
                        else ...[
                          Text(
                            'Verify & Proceed',
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: AppColors.onPrimary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
