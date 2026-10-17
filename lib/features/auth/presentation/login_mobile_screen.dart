import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons.dart';
import 'providers/auth_notifier.dart';
import 'providers/auth_state.dart';

/// The login screen: phone + OTP, or email + password.
///
/// The mobile tab is the original screen, unchanged -- same `+91` prefix, same
/// ten-digit validation, same `requestOtp` call. The email tab is additive:
/// an operator can hand a QA driver an address and a password without an SMS
/// reaching a real phone, and a driver whose SIM is out of service can still
/// get in. Both tabs land on the same session, because the server returns the
/// same envelope for both (asserted in
/// test/auth_contract_conformance_test.dart against its captured output).
class LoginMobileScreen extends ConsumerStatefulWidget {
  const LoginMobileScreen({super.key});

  @override
  ConsumerState<LoginMobileScreen> createState() => _LoginMobileScreenState();
}

class _LoginMobileScreenState extends ConsumerState<LoginMobileScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  late final TabController _tabController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitPhone() {
    if (_phoneFormKey.currentState?.validate() ?? false) {
      final phone = '+91${_phoneController.text.trim()}';
      ref.read(authNotifierProvider.notifier).requestOtp(phone);
    }
  }

  void _submitEmail() {
    if (_emailFormKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).emailLogin(
            email: _emailController.text,
            password: _passwordController.text,
          );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _show('Enter your email address first, then tap Forgot password.');
      return;
    }

    try {
      final message = await ref
          .read(authNotifierProvider.notifier)
          .requestPasswordReset(email);
      if (mounted) _show(message);
    } catch (e) {
      // The server answers the same way for a known and an unknown address;
      // only a transport failure reaches here.
      if (mounted) {
        _show('Could not reach the server. Check your connection and retry.');
      }
    }
  }

  void _show(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isRequestingOtp = authState is AuthRequestingOtp;
    final isSigningIn = authState is AuthSigningIn;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        _show(next.message, isError: true);
      }
      final arrivedWithExpiredSession =
          next is AuthUnauthenticated &&
          next.reason != null &&
          (previous == null || previous is! AuthUnauthenticated);
      if (arrivedWithExpiredSession) {
        _show(next.reason!, isError: true);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mobile', icon: Icon(Icons.smartphone)),
            Tab(text: 'Email', icon: Icon(Icons.alternate_email)),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _mobileTab(isLoading: isRequestingOtp),
            _emailTab(isLoading: isSigningIn),
          ],
        ),
      ),
    );
  }

  Widget _mobileTab({required bool isLoading}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.margin),
      child: Form(
        key: _phoneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Welcome to SaaradhiGo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enter your mobile number to log in or register.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixText: '+91 ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your mobile number';
                }
                if (value.length != 10 || !RegExp(r'^\d+$').hasMatch(value)) {
                  return 'Please enter a valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: 'Send OTP',
              isLoading: isLoading,
              onPressed: isLoading ? () {} : _submitPhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailTab({required bool isLoading}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.margin),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sign in with email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Use the address your account was registered with.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Please enter your email address';
                // Deliberately permissive: the server is the authority on
                // which addresses exist, and a clever client-side pattern
                // only ever rejects somebody's real address.
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => isLoading ? null : _submitEmail(),
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: 'Sign in',
              isLoading: isLoading,
              onPressed: isLoading ? () {} : _submitEmail,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: isLoading ? null : _forgotPassword,
              child: const Text('Forgot password?'),
            ),
          ],
        ),
      ),
    );
  }
}
