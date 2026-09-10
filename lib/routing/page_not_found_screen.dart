import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/buttons.dart';
import 'app_router.dart';

class PageNotFoundScreen extends StatelessWidget {
  final String? errorMessage;

  const PageNotFoundScreen({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                errorMessage ?? 'The page you are looking for does not exist.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Go to Home',
                onPressed: () {
                  context.goNamed(AppRoute.home.name);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
