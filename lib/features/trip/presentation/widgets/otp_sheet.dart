import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../trip_controller.dart';

/// Collects the rider's start-trip OTP.
///
/// The OTP is generated server-side at accept time and delivered to the
/// *rider* only — the driver has to ask for it out loud. That is the whole
/// anti-fraud mechanism: it proves the right person got in the car. The
/// server allows 5 wrong attempts per trip before locking the action, so the
/// error text has to be clear rather than a generic failure.
Future<String?> showOtpSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _OtpSheet(),
  );
}

class _OtpSheet extends ConsumerStatefulWidget {
  const _OtpSheet();

  @override
  ConsumerState<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends ConsumerState<_OtpSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otpError = ref.watch(tripControllerProvider).otpError;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Start the trip',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask the rider for their 6-digit trip code.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 10,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              errorText: otpError,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final otp = _controller.text.trim();
              if (otp.length < 4) return;
              Navigator.of(context).pop(otp);
            },
            child: const Text('Start trip'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
