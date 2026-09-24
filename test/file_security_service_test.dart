import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:miralo/services/file_security_service.dart';

void main() {
  group('FileSecurityService Extension & RTLO Spoofing Tests', () {
    test('Blocks Unicode RTLO spoofing in file name', () {
      // RTLO character: \u202E
      final rtloPayload = 'report\u202Efdp.exe';
      final res = FileSecurityService.validateFile(rawFileName: rtloPayload);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('RTLO'));
    });

    test('Blocks multi-extension and double-extension attack payloads', () {
      final doubleExt1 = FileSecurityService.validateFile(rawFileName: 'invoice.pdf.exe');
      expect(doubleExt1.isValid, isFalse);
      expect(doubleExt1.errorMessage, contains('exe'));

      final doubleExt2 = FileSecurityService.validateFile(rawFileName: 'document.exe.pdf');
      expect(doubleExt2.isValid, isFalse);
      expect(doubleExt2.errorMessage, contains('exe'));

      final doubleExt3 = FileSecurityService.validateFile(rawFileName: 'photo.jpg.sh');
      expect(doubleExt3.isValid, isFalse);
      expect(doubleExt3.errorMessage, contains('sh'));

      final doubleExt4 = FileSecurityService.validateFile(rawFileName: 'archive.apk.zip');
      expect(doubleExt4.isValid, isFalse);
      expect(doubleExt4.errorMessage, contains('apk'));
    });

    test('Blocks direct dangerous and executable formats', () {
      final badFiles = ['setup.bat', 'payload.cmd', 'script.vbs', 'installer.msi', 'binary.elf', 'app.apk', 'script.py'];
      for (final file in badFiles) {
        final res = FileSecurityService.validateFile(rawFileName: file);
        expect(res.isValid, isFalse, reason: '$file should be blocked');
      }
    });

    test('Allows legitimate files and documents', () {
      final goodFiles = ['resume.pdf', 'photo.png', 'quarterly_report.docx', 'data.xlsx', 'notes.txt'];
      for (final file in goodFiles) {
        final res = FileSecurityService.validateFile(rawFileName: file);
        expect(res.isValid, isTrue, reason: '$file should be valid');
      }
    });
  });

  group('FileSecurityService Binary Header Magic Number Sniffing', () {
    test('Blocks Windows PE executable (MZ header: 0x4D, 0x5A) masquerading as PDF', () {
      final peBytes = Uint8List.fromList([0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00]);
      final res = FileSecurityService.validateFile(
        rawFileName: 'fake_invoice.pdf',
        fileBytes: peBytes,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Windows PE'));
    });

    test('Blocks Linux ELF binary (0x7F, E, L, F) masquerading as document', () {
      final elfBytes = Uint8List.fromList([0x7F, 0x45, 0x4C, 0x46, 0x02, 0x01]);
      final res = FileSecurityService.validateFile(
        rawFileName: 'innocent_report.pdf',
        fileBytes: elfBytes,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Linux ELF'));
    });

    test('Blocks Shell script shebang (#! / 0x23, 0x21) masquerading as txt/doc', () {
      final shebangBytes = Uint8List.fromList([0x23, 0x21, 0x2F, 0x62, 0x69, 0x6E]); // #!/bin
      final res = FileSecurityService.validateFile(
        rawFileName: 'innocent_notes.txt',
        fileBytes: shebangBytes,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('executable script shebang'));
    });

    test('Blocks Dalvik DEX bytecode (dex\\n / 0x64, 0x65, 0x78, 0x0A) masquerading as zip', () {
      final dexBytes = Uint8List.fromList([0x64, 0x65, 0x78, 0x0A, 0x30, 0x33]);
      final res = FileSecurityService.validateFile(
        rawFileName: 'archive.zip',
        fileBytes: dexBytes,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Dalvik DEX'));
    });

    test('Blocks WebAssembly bytecode (\\0asm / 0x00, 0x61, 0x73, 0x6D) masquerading as pdf', () {
      final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6D, 0x01, 0x00]);
      final res = FileSecurityService.validateFile(
        rawFileName: 'disguised_doc.pdf',
        fileBytes: wasmBytes,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('WebAssembly'));
    });

    test('Allows safe binary bytes for legitimate PDF and PNG files', () {
      // PDF header: %PDF
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]);
      final resPdf = FileSecurityService.validateFile(
        rawFileName: 'document.pdf',
        fileBytes: pdfBytes,
      );
      expect(resPdf.isValid, isTrue);

      // PNG header: 0x89 PNG
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]);
      final resPng = FileSecurityService.validateFile(
        rawFileName: 'avatar.png',
        fileBytes: pngBytes,
      );
      expect(resPng.isValid, isTrue);
    });
  });
}
