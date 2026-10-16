/// Driver KYC: presigned upload, and vehicle registration.
///
/// THE BLOCKER THESE TESTS COVER
/// -----------------------------
/// A driver could not be onboarded. The backend has accepted documents since
/// the KYC work — `POST /uploads/presign/` then a PUT to S3 then the key
/// submitted to `/driver/vehicles/add/` or `/driver/driver/update/` — and the
/// operator console reviews and approves them. But no UI anywhere called any
/// of it: the driver app's profile screen said "Not uploaded" and offered no
/// way to change that, and the console has no upload form. The only path was
/// hand-written API calls.
///
/// The upload is three steps and the middle one talks to a third party, so
/// these tests pin the parts that are easy to get silently wrong: the exact
/// Content-Type, no auth token sent to S3, the right field names, and the
/// upload kinds matching the server's registry.
library;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/api_client.dart';
import 'package:saaradhigo_driver/core/network/api_exception.dart';
import 'package:saaradhigo_driver/core/network/upload_client.dart';
import 'package:saaradhigo_driver/features/kyc/data/kyc_repository_impl.dart';
import 'package:saaradhigo_driver/features/kyc/domain/document_kind.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHttpAdapter apiAdapter;
  late FakeHttpAdapter s3Adapter;
  late ApiClient api;
  late UploadClient uploads;

  setUp(() {
    apiAdapter = FakeHttpAdapter();
    s3Adapter = FakeHttpAdapter();
    api = ApiClient(
      FakeTokenStore(access: 'access-1', refresh: 'refresh-1'),
      dio: Dio()..httpClientAdapter = apiAdapter,
    );
    uploads = UploadClient(
      api,
      putClient: Dio()..httpClientAdapter = s3Adapter,
    );
  });

  group('upload kinds match the server registry', () {
    test('every document maps to a kind in base/media.py UPLOAD_KINDS', () {
      // Mirrored from `base/media.py`. A kind the registry does not know is
      // refused by /uploads/presign/, so a typo here is a document that can
      // never be submitted — and nothing else in the app would notice.
      const serverKinds = <String>{
        'avatar',
        'vehicle_pic',
        'license_doc',
        'license_doc_back',
        'rc_doc',
        'permit_doc',
        'insurance_doc',
        'fitness_doc',
        'puc_doc',
        'inspection_doc',
      };

      for (final document in DriverDocument.values) {
        expect(serverKinds, contains(document.kind),
            reason: '${document.name} uses kind "${document.kind}", which the '
                'server does not accept');
      }
    });

    test('India needs licence plus five vehicle documents', () {
      expect(DriverDocument.driverDocuments.map((d) => d.kind), [
        'license_doc',
        'license_doc_back',
      ]);
      expect(DriverDocument.vehicleDocuments.map((d) => d.kind), [
        'rc_doc',
        'insurance_doc',
        'permit_doc',
        'fitness_doc',
        'puc_doc',
      ]);
    });
  });

  group('presign', () {
    test('asks for the kind and content type the server expects', () async {
      apiAdapter.enqueue(body: {
        'status': 'success',
        'data': {
          'kind': 'rc_doc',
          'key': 'rc_docs/abc.jpg',
          'upload_url': 'https://s3.example/rc_docs/abc.jpg?sig=1',
          'expires_in': 900,
        },
      });

      final result =
          await uploads.presign(kind: 'rc_doc', contentType: 'image/jpeg');

      final sent = _sentBody(apiAdapter.requests.single);
      expect(apiAdapter.requests.single.path, '/uploads/presign/');
      expect(sent['kind'], 'rc_doc');
      expect(sent['content_type'], 'image/jpeg');

      // The KEY is what gets submitted later, never the signed URL.
      expect(result.key, 'rc_docs/abc.jpg');
    });

    test('a response missing the key is a clear failure, not a null key',
        () async {
      apiAdapter.enqueue(body: {'status': 'success', 'data': {}});

      expect(
        () => uploads.presign(kind: 'rc_doc', contentType: 'image/jpeg'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('the PUT to S3', () {
    test('sends exactly the signed content type, and no auth token', () async {
      final target = const PresignedUpload(
        kind: 'rc_doc',
        key: 'rc_docs/abc.jpg',
        uploadUrl: 'https://s3.example/rc_docs/abc.jpg?sig=1',
      );
      s3Adapter.enqueue(status: 200);

      await uploads.putBytes(
        target: target,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        contentType: 'image/jpeg',
      );

      final request = s3Adapter.requests.single;
      expect(request.method, 'PUT');
      // A different Content-Type than the one signed fails the S3 signature.
      // Dio defaults to application/octet-stream, which is the trap.
      expect(request.headers[Headers.contentTypeHeader], 'image/jpeg');
      // The presigned URL IS the authorisation. Sending a Bearer token to a
      // third party would put it in their access logs for nothing.
      expect(request.headers.containsKey('Authorization'), isFalse);
    });

    test('an S3 error becomes a message a driver can act on', () async {
      s3Adapter.enqueue(status: 403);

      expect(
        () => uploads.putBytes(
          target: const PresignedUpload(
            kind: 'rc_doc',
            key: 'k',
            uploadUrl: 'https://s3.example/k',
          ),
          bytes: Uint8List.fromList([1]),
          contentType: 'image/jpeg',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('try again'),
          ),
        ),
      );
    });
  });

  group('content type is derived from the extension', () {
    test('jpeg, png, webp and pdf are mapped', () {
      expect(UploadClient.contentTypeFor('/tmp/a.jpg'), 'image/jpeg');
      expect(UploadClient.contentTypeFor('/tmp/a.JPEG'), 'image/jpeg');
      expect(UploadClient.contentTypeFor('/tmp/a.png'), 'image/png');
      expect(UploadClient.contentTypeFor('/tmp/a.webp'), 'image/webp');
      expect(UploadClient.contentTypeFor('/tmp/a.pdf'), 'application/pdf');
    });

    test('HEIC is refused with an explanation, not a signature failure', () {
      // iPhone's default format. The server does not accept it, and failing
      // at the S3 signature would tell the driver nothing useful.
      expect(
        () => UploadClient.contentTypeFor('/tmp/IMG_0001.HEIC'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('not supported'),
        )),
      );
    });
  });

  group('uploadFile end to end', () {
    test('presigns, PUTs, and returns the key to submit', () async {
      final file = File(
        '${Directory.systemTemp.createTempSync('kyc').path}/rc.jpg',
      )..writeAsBytesSync(List<int>.filled(1024, 7));

      apiAdapter.enqueue(body: {
        'status': 'success',
        'data': {
          'kind': 'rc_doc',
          'key': 'rc_docs/xyz.jpg',
          'upload_url': 'https://s3.example/rc_docs/xyz.jpg?sig=2',
        },
      });
      s3Adapter.enqueue(status: 200);

      final key = await uploads.uploadFile(kind: 'rc_doc', file: file);

      expect(key, 'rc_docs/xyz.jpg');
      expect(apiAdapter.requests, hasLength(1));
      expect(s3Adapter.requests, hasLength(1));
    });

    test('refuses a file over 10 MB before uploading anything', () async {
      final file = File(
        '${Directory.systemTemp.createTempSync('kyc_big').path}/big.jpg',
      )..writeAsBytesSync(List<int>.filled(11 * 1024 * 1024, 0));

      await expectLater(
        uploads.uploadFile(kind: 'rc_doc', file: file),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('too large'),
        )),
      );

      // Nothing was presigned: a driver on mobile data is not made to upload
      // 11 MB before being told no.
      expect(apiAdapter.requests, isEmpty);
      expect(s3Adapter.requests, isEmpty);
    });
  });

  group('vehicle registration', () {
    test('submits the registration number upper-cased and trimmed', () async {
      apiAdapter.enqueue(body: {
        'status': 'success',
        'data': {'id': 12},
      });

      final id = await KycRepository(api).createVehicle(
        draft: const VehicleDraft(
          vehicleNumber: '  ts09ab1234 ',
          vehicleType: 'sedan',
          brand: 'Maruti',
          model: 'Dzire',
          color: 'White',
        ),
      );

      final sent = _sentBody(apiAdapter.requests.single);
      expect(apiAdapter.requests.single.path, '/driver/vehicles/add/');
      expect(sent['vehicle_number'], 'TS09AB1234');
      expect(sent['vehicle_type'], 'sedan');
      expect(sent['brand'], 'Maruti');
      expect(id, 12);
    });

    test('attaches vehicle document keys under their API field names',
        () async {
      apiAdapter.enqueue(body: {'status': 'success', 'data': {'id': 3}});

      await KycRepository(api).createVehicle(
        draft: const VehicleDraft(
          vehicleNumber: 'TS09AB1234',
          vehicleType: 'auto',
        ),
        documentKeys: {
          DriverDocument.registrationCertificate: 'rc_docs/a.jpg',
          DriverDocument.insurance: 'insurance_docs/b.jpg',
          // A driver document must NOT be sent to the vehicle endpoint.
          DriverDocument.licenceFront: 'license_docs/c.jpg',
        },
      );

      final sent = _sentBody(apiAdapter.requests.single);
      expect(sent['rc_doc'], 'rc_docs/a.jpg');
      expect(sent['insurance_doc'], 'insurance_docs/b.jpg');
      expect(sent.containsKey('license_doc'), isFalse);
    });

    test('omits empty optional fields rather than sending blanks', () async {
      apiAdapter.enqueue(body: {'status': 'success', 'data': {'id': 4}});

      await KycRepository(api).createVehicle(
        draft: const VehicleDraft(
          vehicleNumber: 'TS09AB1234',
          vehicleType: 'suv',
          brand: '   ',
        ),
      );

      final sent = _sentBody(apiAdapter.requests.single);
      expect(sent.containsKey('brand'), isFalse);
      expect(sent.containsKey('year'), isFalse);
    });
  });

  group('driver documents', () {
    test('PATCHes only the licence keys that were uploaded', () async {
      apiAdapter.enqueue(body: {'status': 'success', 'data': {}});

      await KycRepository(api).submitDriverDocuments({
        DriverDocument.licenceFront: 'license_docs/front.jpg',
        // Back not uploaded in this pass.
        DriverDocument.registrationCertificate: 'rc_docs/a.jpg',
      });

      final sent = _sentBody(apiAdapter.requests.single);
      expect(apiAdapter.requests.single.path, '/driver/driver/update/');
      expect(sent['license_doc'], 'license_docs/front.jpg');
      // Sending `license_doc_back: null` would clear a document the driver
      // had already supplied.
      expect(sent.containsKey('license_doc_back'), isFalse);
      // A vehicle document does not belong on the driver endpoint.
      expect(sent.containsKey('rc_doc'), isFalse);
    });

    test('sends nothing at all when no driver document is uploaded', () async {
      await KycRepository(api).submitDriverDocuments({
        DriverDocument.insurance: 'insurance_docs/b.jpg',
      });

      expect(apiAdapter.requests, isEmpty);
    });
  });
}

/// The body Dio was handed, as a Map.
///
/// `RequestOptions.data` holds the object the caller passed, not a serialised
/// string -- Dio serialises later, in the adapter it never reaches here.
Map<String, dynamic> _sentBody(RequestOptions options) =>
    (options.data as Map).cast<String, dynamic>();
