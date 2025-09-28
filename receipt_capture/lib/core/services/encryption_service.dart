import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class EncryptionService {
  late final Encrypter _encrypter;
  late final IV _iv;

  EncryptionService._privateConstructor() {
    _initializeEncryption();
  }

  static final EncryptionService instance =
      EncryptionService._privateConstructor();

  void _initializeEncryption() {
    // Generate a secure key (in production, use secure key storage)
    final key = Key.fromSecureRandom(32);
    _iv = IV.fromSecureRandom(16);
    _encrypter = Encrypter(AES(key));
  }

  String encryptData(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  String decryptData(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Map<String, dynamic> encryptReceiptData(Map<String, dynamic> receiptData) {
    final sensitiveFields = ['merchant_name', 'amount', 'notes'];
    final encryptedData = <String, dynamic>{};

    for (final entry in receiptData.entries) {
      if (sensitiveFields.contains(entry.key) && entry.value != null) {
        encryptedData[entry.key] = encryptData(entry.value.toString());
      } else {
        encryptedData[entry.key] = entry.value;
      }
    }

    return encryptedData;
  }

  Map<String, dynamic> decryptReceiptData(
    Map<String, dynamic> encryptedReceiptData,
  ) {
    final sensitiveFields = ['merchant_name', 'amount', 'notes'];
    final decryptedData = <String, dynamic>{};

    for (final entry in encryptedReceiptData.entries) {
      if (sensitiveFields.contains(entry.key) && entry.value != null) {
        try {
          decryptedData[entry.key] = decryptData(entry.value.toString());
        } catch (e) {
          // If decryption fails, return original value
          decryptedData[entry.key] = entry.value;
        }
      } else {
        decryptedData[entry.key] = entry.value;
      }
    }

    return decryptedData;
  }
}
