import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Which credential the driver is using.
///
/// Mobile + OTP stays the default: it is what a driver partner has, it needs
/// no password, and it is the only route that can create an account. Email is
/// for a driver who has set a password, and for QA accounts that must be
/// reachable without waiting on SMS delivery.
enum LoginMode { mobile, email }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginMode _mode = LoginMode.mobile;
  bool _showPassword = false;

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final ok = await ref.read(authControllerProvider.notifier).emailLogin(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    if (ok) {
      // Straight to the app: the password WAS the proof, so there is no OTP
      // step to go through.
      context.go(Routes.home);
      return;
    }
    final error = ref.read(authControllerProvider).error;
    if (error != null) showErrorSnack(context, error);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email address first, then tap again'),
        ),
      );
      return;
    }

    await ref.read(authControllerProvider.notifier)
        .requestPasswordReset(email);
    if (!mounted) return;

    // The same message whatever the server found -- it deliberately does not
    // confirm whether an account exists.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'If that address belongs to an account, we have sent a reset link.',
        ),
      ),
    );
  }

  /// The backend stores and matches E.164. Accepting a bare 10-digit number
  /// and normalising here is what most Indian drivers will actually type.
  String _e164(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return '+$digits';
  }

  String? _validate(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter your mobile number';
    if (digits.length < 10) return 'That number looks too short';
    if (digits.length == 10 && !RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Indian mobile numbers start with 6, 7, 8 or 9';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestOtp(_e164(_controller.text));

    if (!mounted) return;
    if (ok) {
      context.go(Routes.otp);
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) showErrorSnack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.brand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_taxi_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Drive with SaaradhiGo',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _mode == LoginMode.mobile
                      ? 'Sign in with the mobile number registered with your '
                          'driver account.'
                      : 'Sign in with the email address and password on your '
                          'driver account.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Mobile | Email. Mobile first and default.
                SegmentedButton<LoginMode>(
                  key: const Key('login_mode_tabs'),
                  segments: const [
                    ButtonSegment(
                      value: LoginMode.mobile,
                      label: Text('Mobile'),
                      icon: Icon(Icons.sms_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: LoginMode.email,
                      label: Text('Email'),
                      icon: Icon(Icons.alternate_email, size: 18),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) => setState(() {
                    _mode = selection.first;
                    // The form holds different fields per mode, so a
                    // validation error from the other one must not linger.
                    _formKey.currentState?.reset();
                  }),
                ),
                const SizedBox(height: 24),

                if (_mode == LoginMode.mobile)
                  TextFormField(
                    key: const Key('login_phone_field'),
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    validator: _validate,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixText: '+91  ',
                      hintText: '9XXXXXXXXX',
                    ),
                  ),

                if (_mode == LoginMode.email) ...[
                  TextFormField(
                    key: const Key('login_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return 'Enter your email address';
                      if (!text.contains('@') || !text.contains('.')) {
                        return 'That does not look like an email address';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('login_password_field'),
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitEmail(),
                    validator: (value) => (value ?? '').isEmpty
                        ? 'Enter your password'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        key: const Key('login_password_visibility'),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('login_forgot_password'),
                      onPressed: auth.isBusy ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('login_submit'),
                  onPressed: auth.isBusy
                      ? null
                      : (_mode == LoginMode.mobile ? _submit : _submitEmail),
                  child: auth.isBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(_mode == LoginMode.mobile
                          ? 'Send OTP'
                          : 'Sign in'),
                ),
                const SizedBox(height: 20),
                Text(
                  'By continuing you agree to the SaaradhiGo Driver Partner '
                  'agreement and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
