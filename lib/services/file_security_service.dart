import 'dart:typed_data';

/// Result of file security validation.
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String sanitizedFileName;

  const FileValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.sanitizedFileName,
  });
}

/// Comprehensive security service to block extension spoofing, RTLO attacks,
/// double-extension payloads, and binary magic-number header mismatches.
class FileSecurityService {
  /// Blocked executable and script extensions across all platforms
  static const Set<String> blockedExtensions = {
    // Windows Executables & Scripts
    'exe', 'bat', 'cmd', 'vbs', 'vbe', 'js', 'jse', 'ws', 'wsf', 'wsc', 'wsh',
    'scr', 'msi', 'msp', 'mst', 'com', 'pif', 'application', 'gadget', 'cpl',
    'ps1', 'ps1xml', 'ps2', 'ps2xml', 'psc1', 'psc2', 'reg', 'hta', 'inf',
    'sys', 'dll', 'drv', 'ocx',
    // Linux / Unix Executables & Binaries
    'sh', 'bash', 'zsh', 'ksh', 'csh', 'elf', 'bin', 'out', 'run',
    // macOS Binaries & Packages
    'dylib', 'app', 'pkg', 'dmg', 'command',
    // Mobile / Java / Bytecode
    'apk', 'aab', 'dex', 'jar', 'class', 'wasm',
    // Scripting languages
    'py', 'pyc', 'pyo', 'pyd', 'rb', 'pl', 'php', 'cgi', 'asp', 'aspx', 'jsp',
  };

  /// Disallowed Unicode characters (RTLO, LRO, null bytes, bidirectional formatting)
  static final RegExp _spoofingCharsRegex = RegExp(
    r'[\u0000\u202A-\u202E\u200E\u200F\u2066-\u2069\r\n\t]',
  );

  /// Validates a file by inspecting its name, all extension segments, and binary header bytes.
  static FileValidationResult validateFile({
    required String rawFileName,
    Uint8List? fileBytes,
  }) {
    // 1. Check for Unicode RTLO or Null Byte spoofing in filename
    if (_spoofingCharsRegex.hasMatch(rawFileName)) {
      return FileValidationResult(
        isValid: false,
        errorMessage: 'Blocked: Malicious unicode / Right-to-Left Override (RTLO) spoofing detected.',
        sanitizedFileName: _sanitizeFileName(rawFileName),
      );
    }

    final sanitizedName = _sanitizeFileName(rawFileName);

    // 2. Multi-extension & Double Extension Spoofing Detection
    // e.g. "invoice.pdf.exe", "photo.jpg.sh", "doc.exe.pdf"
    final segments = sanitizedName.split('.').where((s) => s.isNotEmpty).toList();
    if (segments.length > 1) {
      // Check every extension segment against blocked executable extensions
      for (int i = 1; i < segments.length; i++) {
        final extSegment = segments[i].toLowerCase().trim();
        if (blockedExtensions.contains(extSegment)) {
          return FileValidationResult(
            isValid: false,
            errorMessage: 'Blocked: Executable / dangerous extension segment (.$extSegment) detected.',
            sanitizedFileName: sanitizedName,
          );
        }
      }
    }

    // 3. Final extension check
    final finalExt = segments.isNotEmpty && sanitizedName.contains('.')
        ? segments.last.toLowerCase().trim()
        : '';

    if (blockedExtensions.contains(finalExt)) {
      return FileValidationResult(
        isValid: false,
        errorMessage: 'Blocked: Executable file format (.$finalExt) is blocked for security.',
        sanitizedFileName: sanitizedName,
      );
    }

    // 4. Binary Magic Number / Header Inspection (Anti-Payload Masquerading)
    if (fileBytes != null && fileBytes.isNotEmpty) {
      final binaryCheck = _inspectBinaryHeader(fileBytes, finalExt);
      if (!binaryCheck.isValid) {
        return FileValidationResult(
          isValid: false,
          errorMessage: binaryCheck.errorMessage,
          sanitizedFileName: sanitizedName,
        );
      }
    }

    return FileValidationResult(
      isValid: true,
      sanitizedFileName: sanitizedName,
    );
  }

  /// Inspects raw header bytes for binary executable signatures masquerading as safe files
  static FileValidationResult _inspectBinaryHeader(Uint8List bytes, String claimedExt) {
    if (bytes.length < 4) {
      return const FileValidationResult(isValid: true, sanitizedFileName: '');
    }

    // Windows PE Executable (MZ header: 0x4D, 0x5A)
    if (bytes[0] == 0x4D && bytes[1] == 0x5A) {
      return const FileValidationResult(
        isValid: false,
        errorMessage: 'Blocked: File content has Windows PE executable signature (MZ header).',
        sanitizedFileName: '',
      );
    }

    // Linux / Android ELF Binary (0x7F, 'E', 'L', 'F')
    if (bytes[0] == 0x7F && bytes[1] == 0x45 && bytes[2] == 0x4C && bytes[3] == 0x46) {
      return const FileValidationResult(
        isValid: false,
        errorMessage: 'Blocked: File content has Linux ELF executable signature.',
        sanitizedFileName: '',
      );
    }

    // macOS Mach-O Binary signatures
    if ((bytes[0] == 0xFE && bytes[1] == 0xED && bytes[2] == 0xFA && (bytes[3] == 0xCE || bytes[3] == 0xCF)) ||
        (bytes[0] == 0xCF && bytes[1] == 0xFA && bytes[2] == 0xED && bytes[3] == 0xFE) ||
        (bytes[0] == 0xCA && bytes[1] == 0xFE && bytes[2] == 0xBA && bytes[3] == 0xBE && claimedExt != 'class')) {
      return const FileValidationResult(
        isValid: false,
        errorMessage: 'Blocked: File content has Mach-O binary signature.',
        sanitizedFileName: '',
      );
    }

    // Android DEX / Dalvik Bytecode ("dex\n": 0x64, 0x65, 0x78, 0x0A)
    if (bytes[0] == 0x64 && bytes[1] == 0x65 && bytes[2] == 0x78 && bytes[3] == 0x0A) {
      return const FileValidationResult(
        isValid: false,
        errorMessage: 'Blocked: File content contains Dalvik DEX bytecode.',
        sanitizedFileName: '',
      );
    }

    // WebAssembly Binary ("\0asm": 0x00, 0x61, 0x73, 0x6D)
    if (bytes[0] == 0x00 && bytes[1] == 0x61 && bytes[2] == 0x73 && bytes[3] == 0x6D) {
      return const FileValidationResult(
        isValid: false,
        errorMessage: 'Blocked: File content contains WebAssembly executable bytecode.',
        sanitizedFileName: '',
      );
    }

    // Unix Shell Script Shebang ("#!": 0x23, 0x21)
    if (bytes[0] == 0x23 && bytes[1] == 0x21) {
      return const FileValidationResult(
        isValid: false,
        errorMessage: 'Blocked: File content contains executable script shebang (#!).',
        sanitizedFileName: '',
      );
    }

    return const FileValidationResult(isValid: true, sanitizedFileName: '');
  }

  /// Strips dangerous characters and path traversal from filename
  static String _sanitizeFileName(String fileName) {
    // Strip RTLO / control characters
    var clean = fileName.replaceAll(_spoofingCharsRegex, '');
    // Strip directory traversal
    clean = clean.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    // Trim leading and trailing whitespace/dots
    clean = clean.trim();
    while (clean.startsWith('.')) {
      clean = clean.substring(1).trim();
    }
    return clean.isEmpty ? 'unnamed_file' : clean;
  }
}
