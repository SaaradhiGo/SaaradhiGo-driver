/// Register a vehicle and attach its papers.
///
/// Second half of onboarding. `POST /driver/vehicles/add/` creates the vehicle
/// AND stores the document keys in one request, so the documents are collected
/// here alongside the registration number rather than on a later screen.
///
/// WHAT THIS SCREEN DOES NOT DECIDE
/// --------------------------------
/// Whether the document set is complete. That is a server-side,
/// country-driven decision (`servers/driver/compliance.py`), the operator
/// console approves against it, and a second copy of the rule in the app would
/// be a second answer to the same question. The screen asks for India's five
/// vehicle documents because India is the launch market, submits what it has,
/// and lets the server and the operator judge it.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../data/kyc_repository_impl.dart';
import '../domain/document_kind.dart';
import 'kyc_controller.dart';
import 'widgets/document_tile.dart';

/// The vehicle types the platform prices. These are the `VehicleType.type`
/// rows seeded by `pricing/0002_seed_phase0_data.py`; the server looks the
/// value up and 400s on anything else, and there is no endpoint that lists
/// them, so the list is mirrored here with that migration named as its source.
const List<({String value, String label})> kVehicleTypes = [
  (value: 'auto', label: 'Auto rickshaw'),
  (value: 'hatchback', label: 'Hatchback'),
  (value: 'sedan', label: 'Sedan'),
  (value: 'suv', label: 'SUV'),
];

class VehicleRegistrationScreen extends ConsumerStatefulWidget {
  const VehicleRegistrationScreen({super.key});

  static const String routePath = '/kyc/vehicle';

  @override
  ConsumerState<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState
    extends ConsumerState<VehicleRegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _colour = TextEditingController();
  String _type = 'sedan';

  @override
  void dispose() {
    _number.dispose();
    _brand.dispose();
    _model.dispose();
    _colour.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    final controller = ref.read(kycControllerProvider.notifier);
    final ok = await controller.submitVehicle(
      VehicleDraft(
        vehicleNumber: _number.text,
        vehicleType: _type,
        brand: _brand.text,
        model: _model.text,
        color: _colour.text,
      ),
    );
    if (!ok || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehicle submitted. Our team will review your '
            'documents.'),
      ),
    );
    context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final controller = ref.read(kycControllerProvider.notifier);
    final documents = DriverDocument.vehicleDocuments;

    return Scaffold(
      appBar: AppBar(title: const Text('Your vehicle')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('vehicle_number'),
              controller: _number,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                UpperCaseFormatter(),
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9 -]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: const InputDecoration(
                labelText: 'Registration number',
                hintText: 'TS09AB1234',
              ),
              validator: (value) {
                final v = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
                if (v.isEmpty) return 'Enter the number on your number plate';
                // Deliberately loose. Indian plate formats vary by state and
                // era (BH series, older two-letter codes), and a strict regex
                // here would lock out legitimate drivers. The operator sees
                // the RC photo and is the real check.
                if (v.length < 6) return 'That looks too short';
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const Key('vehicle_type'),
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Vehicle type'),
              items: [
                for (final type in kVehicleTypes)
                  DropdownMenuItem(value: type.value, child: Text(type.label)),
              ],
              onChanged: (value) =>
                  setState(() => _type = value ?? 'sedan'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('vehicle_brand'),
                    controller: _brand,
                    decoration: const InputDecoration(labelText: 'Make'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('vehicle_model'),
                    controller: _model,
                    decoration: const InputDecoration(labelText: 'Model'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('vehicle_colour'),
              controller: _colour,
              decoration: const InputDecoration(labelText: 'Colour'),
            ),
            const SizedBox(height: 22),
            Text('Vehicle documents',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            for (final document in documents) ...[
              DocumentTile(
                document: document,
                slot: state.slot(document),
                onPick: (source) =>
                    controller.pickAndUpload(document, source: source),
                onRemove: () => controller.remove(document),
              ),
              const SizedBox(height: 10),
            ],
            if (state.submitError != null) ...[
              const SizedBox(height: 6),
              Text(
                state.submitError!,
                key: const Key('vehicle_submit_error'),
                style: const TextStyle(color: AppTheme.danger),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('vehicle_submit'),
              // Blocked while an upload is in flight: submitting now would
              // create the vehicle with only the documents that happened to
              // have finished.
              onPressed: state.submitting || state.anyUploading
                  ? null
                  : _submit,
              child: state.submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit vehicle'),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'You can add missing documents later from your profile.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Number plates are upper case. Doing it as a formatter rather than on submit
/// means the driver sees what will be stored.
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      );
}
