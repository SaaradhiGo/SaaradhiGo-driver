import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/uploads/mime_resolver.dart';
import 'package:saaradhigo_driver/core/uploads/upload_kind.dart';

const resolver = MimeTypeResolver();

String? resolveOrNull(String? fileName) =>
    resolver.resolve(fileName: fileName, bytes: Uint8List(0));

void main() {
  group('MimeTypeResolver', () {
    test('resolves common extensions via the allow-list', () {
      expect(resolver.resolve(fileName: 'rc.png'), 'image/png');
      expect(resolver.resolve(fileName: 'photo.JPG'), 'image/jpeg');
      expect(resolver.resolve(fileName: 'scan.jpeg'), 'image/jpeg');
      expect(resolver.resolve(fileName: 'pic.webp'), 'image/webp');
      expect(resolveOrNull('anim.gif'), 'image/gif');
      expect(resolveOrNull('licence.pdf'), 'application/pdf');
    });

    test('falls back to the mime package for unusual names', () {
      // Uppercase/odd but valid extension still resolves.
      expect(resolveOrNull('doc.PDF'), 'application/pdf');
      // Broad fallback resolves unknown-but-known extensions; the per-kind
      // allow-list in UploadValidator is what ultimately rejects them.
      expect(resolveOrNull('archive.zip'), 'application/zip');
      expect(resolveOrNull('noext'), isNull);
      expect(resolveOrNull(null), isNull);
    });

    test('rejecting unknown types produces friendly per-kind hints', () {
      expect(
        UploadValidator.validate(
          kind: UploadKind.rcDoc,
          mimeType: 'application/zip',
          byteLength: 10,
        ),
        contains('PDF'),
      );
      expect(
        UploadValidator.validate(
          kind: UploadKind.avatar,
          mimeType: 'image/png',
          byteLength: 10,
        ),
        isNull,
      );
      expect(
        UploadValidator.validate(
          kind: UploadKind.avatar,
          mimeType: 'application/pdf',
          byteLength: 10,
        ),
        contains('Unsupported file type'),
      );
      expect(
        UploadValidator.validate(
          kind: UploadKind.licenseDoc,
          mimeType: 'application/pdf',
          byteLength: 10,
        ),
        isNull,
      );
      expect(
        UploadValidator.validate(
          kind: UploadKind.vehiclePic,
          mimeType: 'image/png',
          byteLength: UploadKind.maxBytes + 1,
        ),
        contains('5 MB'),
      );
    });
  });
}
