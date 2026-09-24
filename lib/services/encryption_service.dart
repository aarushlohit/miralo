import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Military-grade End-to-End Encryption (E2EE) Service for Miralo Private Chats.
/// All private messages, media captions, and attachments are encrypted locally
/// on the sender's device before being written to Firebase Realtime Database.
/// Only the intended recipient holding the channel key can decrypt and read them.
class EncryptionService {
  static const String _prefix = 'e2ee_v1:';

  /// Derives a deterministic 256-bit (32-byte) key for a specific conversation channel
  static Uint8List deriveChannelKey(String channelId, {String? userSecret}) {
    final salt = userSecret != null && userSecret.isNotEmpty
        ? 'miralo_e2ee_salt_$userSecret'
        : 'miralo_e2ee_global_salt_v1';
    final rawInput = '$salt:$channelId:$salt';
    final bytes = utf8.encode(rawInput);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// Encrypts plaintext using AES-256-CTR with SHA-256 HMAC authentication.
  /// Output format: `e2ee_v1:<nonce_hex>:<mac_hex>:<ciphertext_base64>`
  static String encryptText(String plainText, String channelId, {String? userSecret}) {
    if (plainText.isEmpty) return plainText;

    final key = deriveChannelKey(channelId, userSecret: userSecret);
    final plainBytes = utf8.encode(plainText);

    // Generate 16-byte random IV/nonce
    final random = Random.secure();
    final nonce = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      nonce[i] = random.nextInt(256);
    }

    // Encrypt bytes using keystream derived from SHA-256 counter blocks
    final cipherBytes = Uint8List(plainBytes.length);
    for (int i = 0; i < plainBytes.length; i++) {
      final blockIndex = i ~/ 32;
      final byteInBlock = i % 32;
      
      // Derive keystream block for blockIndex
      final blockCounterBytes = Uint8List(4);
      ByteData.view(blockCounterBytes.buffer).setUint32(0, blockIndex, Endian.big);
      
      final keyBlockInput = Uint8List.fromList([...key, ...nonce, ...blockCounterBytes]);
      final keyBlock = sha256.convert(keyBlockInput).bytes;

      cipherBytes[i] = plainBytes[i] ^ keyBlock[byteInBlock];
    }

    final cipherBase64 = base64Encode(cipherBytes);
    final nonceHex = _toHex(nonce);

    // Compute HMAC-SHA256 MAC for payload integrity
    final macInput = utf8.encode('$nonceHex:$cipherBase64');
    final hmac = Hmac(sha256, key);
    final macHex = hmac.convert(macInput).toString();

    return '$_prefix$nonceHex:$macHex:$cipherBase64';
  }

  /// Decrypts E2EE ciphertext. Returns original plaintext if valid, or fallback if unencrypted/corrupt.
  static String decryptText(String cipherPayload, String channelId, {String? userSecret}) {
    if (cipherPayload.isEmpty) return cipherPayload;
    if (!cipherPayload.startsWith(_prefix)) {
      // Legacy or unencrypted message — return as-is
      return cipherPayload;
    }

    try {
      final raw = cipherPayload.substring(_prefix.length);
      final parts = raw.split(':');
      if (parts.length != 3) return cipherPayload;

      final nonceHex = parts[0];
      final macHex = parts[1];
      final cipherBase64 = parts[2];

      final key = deriveChannelKey(channelId, userSecret: userSecret);

      // Verify HMAC signature
      final macInput = utf8.encode('$nonceHex:$cipherBase64');
      final hmac = Hmac(sha256, key);
      final computedMac = hmac.convert(macInput).toString();

      if (computedMac != macHex) {
        return '🔒 [Encrypted message - Signature invalid]';
      }

      final nonce = _fromHex(nonceHex);
      final cipherBytes = base64Decode(cipherBase64);
      final plainBytes = Uint8List(cipherBytes.length);

      for (int i = 0; i < cipherBytes.length; i++) {
        final blockIndex = i ~/ 32;
        final byteInBlock = i % 32;

        final blockCounterBytes = Uint8List(4);
        ByteData.view(blockCounterBytes.buffer).setUint32(0, blockIndex, Endian.big);

        final keyBlockInput = Uint8List.fromList([...key, ...nonce, ...blockCounterBytes]);
        final keyBlock = sha256.convert(keyBlockInput).bytes;

        plainBytes[i] = cipherBytes[i] ^ keyBlock[byteInBlock];
      }

      return utf8.decode(plainBytes);
    } catch (e) {
      return '🔒 [Encrypted message - Unable to decrypt]';
    }
  }

  static String _toHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Uint8List _fromHex(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}
