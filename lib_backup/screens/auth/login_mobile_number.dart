import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../navigation/route_names.dart';

class LoginMobileNumberScreen extends StatefulWidget {
  const LoginMobileNumberScreen({super.key});

  @override
  State<LoginMobileNumberScreen> createState() =>
      _LoginMobileNumberScreenState();
}

class _LoginMobileNumberScreenState extends State<LoginMobileNumberScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Extract raw digits from the formatted phone text
  String _getRawPhoneNumber() {
    return _controller.text.replaceAll(' ', '');
  }

  /// Handle Continue button press: validate, send OTP, navigate
  Future<void> _onContinuePressed() async {
    final rawNumber = _getRawPhoneNumber();

    // Validate 10-digit Indian mobile number
    if (rawNumber.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid 10-digit mobile number',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onErrorContainer,
            ),
          ),
          backgroundColor: AppColors.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final phoneE164 = '+91$rawNumber';
    final response = await AuthService.sendOtp(phoneE164);
    debugPrint(response.data?.toString());
    debugPrint(response.statusCode.toString());
    debugPrint(response.message);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      Navigator.pushNamed(context, RouteNames.otp, arguments: phoneE164);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? 'Failed to send OTP. Please try again.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onErrorContainer,
            ),
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
      body: Stack(
        children: [
          // Background Texture/Gradient
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.4,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.5),
                    radius: 0.8,
                    colors: [Color(0xFF38342B), Color(0xFF16130B)],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.containerMargin,
                          vertical: AppSpacing.stackLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 48), // mt-12 md:mt-24
                            // Header Section
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome to SaaradhiGo',
                                    style: AppTypography.displayLg.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.stackSm),
                                  Text(
                                    'Enter your mobile number to get started.',
                                    style: AppTypography.bodyLg.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.stackLg),

                            // Input Section
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 20,
                                  sigmaY: 20,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    AppSpacing.stackMd,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF151515,
                                    ).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MOBILE NUMBER',
                                        style: AppTypography.labelCaps.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                right: BorderSide(
                                                  color:
                                                      AppColors.outlineVariant,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              '+91',
                                              style: AppTypography.bodyLg
                                                  .copyWith(
                                                    color: AppColors.onSurface,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: _controller,
                                              focusNode: _focusNode,
                                              keyboardType: TextInputType.phone,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                LengthLimitingTextInputFormatter(
                                                  10,
                                                ),
                                                _PhoneNumberFormatter(),
                                              ],
                                              style: AppTypography.displayLg
                                                  .copyWith(
                                                    color: AppColors.onSurface,
                                                    fontSize:
                                                        24, // adjust to match visual weight
                                                  ),
                                              decoration: InputDecoration(
                                                hintText: '00000 00000',
                                                hintStyle: AppTypography
                                                    .displayLg
                                                    .copyWith(
                                                      color: AppColors
                                                          .onSurfaceVariant
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      fontSize: 24,
                                                    ),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: AppSpacing.stackMd,
                                      ),
                                      // Animated bottom border
                                      Stack(
                                        alignment: Alignment.centerLeft,
                                        children: [
                                          Container(
                                            height: 2,
                                            width: double.infinity,
                                            color: AppColors.outlineVariant,
                                          ),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                              begin: 0.0,
                                              end: _isFocused ? 1.0 : 0.0,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeOut,
                                            builder: (context, value, child) {
                                              return FractionallySizedBox(
                                                widthFactor: value,
                                                child: child,
                                              );
                                            },
                                            child: Container(
                                              height: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.stackLg),

                            // Primary Action Button
                            Container(
                              height: 56, // h-14
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryContainer,
                                    AppColors.primaryFixedDim,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryContainer
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: _isLoading ? null : _onContinuePressed,
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color:
                                                  AppColors.onPrimaryContainer,
                                            ),
                                          )
                                        : Text(
                                            'Continue',
                                            style: AppTypography.headlineMd
                                                .copyWith(
                                                  color: AppColors
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Footer Section
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.stackMd,
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'By continuing, you agree to our\n',
                                    ),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.primary,
                                        decoration: TextDecoration
                                            .none, // Can be underline if needed
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.primary,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String text = newValue.text.replaceAll(' ', '');
    String formatted = '';

    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      if (i == 4 && i != text.length - 1) {
        formatted += ' ';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
