import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons.dart';
import 'providers/auth_notifier.dart';
import 'providers/auth_state.dart';

class LoginMobileScreen extends ConsumerStatefulWidget {
  const LoginMobileScreen({super.key});

  @override
  ConsumerState<LoginMobileScreen> createState() => _LoginMobileScreenState();
}

class _LoginMobileScreenState extends ConsumerState<LoginMobileScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final phone = '+91${_phoneController.text.trim()}';
      ref.read(authNotifierProvider.notifier).requestOtp(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthRequestingOtp;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      final arrivedWithExpiredSession =
          next is AuthUnauthenticated &&
          next.reason != null &&
          (previous == null || previous is! AuthUnauthenticated);
      if (arrivedWithExpiredSession) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.reason!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Form(
            key: _formKey,
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
                    if (value.length != 10 ||
                        !RegExp(r'^\d+$').hasMatch(value)) {
                      return 'Please enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  text: 'Send OTP',
                  isLoading: isLoading,
                  onPressed: isLoading ? () {} : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
