import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/features/profile/delete/delete_account.dart';

class _Api extends DeleteAccountApi {
  _Api(this._info) : super(Dio());
  final DeleteInfo _info;
  
  int posts = 0;
  @override
  Future<DeleteInfo> info() async => _info;
  @override
  Future<DeleteResult> delete(String reason) async {
    posts++;
    return const DeleteResult(closed: false, message: 'Later.');
  }
}

Widget _host(_Api api) => ProviderScope(
  overrides: [deleteAccountApiProvider.overrideWithValue(api)],
  child: const MaterialApp(home: DeleteAccountScreen()),
);

void main() {
  test('parses the server body and falls back on empty lists', () {
    final i = DeleteInfo.fromJson({
      'deleted': ['A.'],
      'kept': <String>[],
      'pending_payouts': {
        'balance': '123.45',
        'currency': 'INR',
        'in_flight': 1,
      },
      'closure': {'status': 'waiting_payouts', 'requested_at': 'x'},
    });
    expect(i.deleted, ['A.']);
    expect(i.kept, kFallbackKept);
    expect(i.pending!.owed, isTrue);
    expect(i.closing, isTrue);
    expect(DeleteInfo.fromJson({'pending_payouts': null}).pending, isNull);
  });

  testWidgets('shows both lists, what is owed, and needs DELETE typed', (
    t,
  ) async {
    final api = _Api(
      DeleteInfo.fromJson({
        'deleted': ['Your profile.'],
        'kept': ['Trips, kept for 8 years.'],
        'pending_payouts': {
          'balance': '123.45',
          'currency': 'INR',
          'in_flight': 1,
        },
      }),
    );
    await t.pumpWidget(_host(api));
    await t.pumpAndSettle();
    expect(find.text('Your profile.'), findsOneWidget);
    expect(find.text('Trips, kept for 8 years.'), findsOneWidget);
    expect(find.byKey(const Key('delete_owed')), findsOneWidget);
    expect(
      find.textContaining('saaradhigo.com/delete-account'),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('delete_submit')));
    expect(api.posts, 0);
    await t.enterText(find.byKey(const Key('delete_confirm_field')), 'DELETE');
    await t.pump();
    await t.ensureVisible(find.byKey(const Key('delete_submit')));
    await t.tap(find.byKey(const Key('delete_submit')));
    await t.pumpAndSettle();
    expect(api.posts, 1);
    expect(find.text('Later.'), findsOneWidget);
    expect(find.byKey(const Key('delete_submit')), findsNothing);
  });

  testWidgets('a closure in progress replaces the button', (t) async {
    await t.pumpWidget(
      _host(
        _Api(
          DeleteInfo.fromJson({
            'closure': {'status': 'waiting_payouts'},
          }),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(
      find.text('Closing: waiting for your earnings to be paid'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('delete_submit')), findsNothing);
  });
}
