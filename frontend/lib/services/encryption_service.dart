import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndiscord/services/api_service.dart';

class EncryptionService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final EcdhP256 _ecdh = EcdhP256();
  final EcdsaP256 _ecdsa = EcdsaP256();
  final AesGcm _aesGcm = AesGcm.with256bits();

  SimpleKeyPair? _identityKeyPair;
  SimpleKeyPair? _signedPreKeyPair;
  final Map<String, SimpleKeyPair> _sessionKeys = {};

  Future<void> initialize() async {
    await _loadOrGenerateKeys();
    await _uploadPublicKeys();
  }

  Future<void> _loadOrGenerateKeys() async {
    final storedIdentity = await _storage.read(key: 'identity_key_private');
    if (storedIdentity != null) {
      _identityKeyPair = await _ecdh.newKeyPairFromSeed(
        base64Decode(storedIdentity).sublist(0, 32),
      );
    } else {
      _identityKeyPair = await _ecdh.newKeyPair();
      final privateKey = await _identityKeyPair!.extractPrivateKeyBytes();
      await _storage.write(key: 'identity_key_private', value: base64Encode(privateKey));
    }

    final storedSigned = await _storage.read(key: 'signed_prekey_private');
    if (storedSigned != null) {
      _signedPreKeyPair = await _ecdh.newKeyPairFromSeed(
        base64Decode(storedSigned).sublist(0, 32),
      );
    } else {
      _signedPreKeyPair = await _ecdh.newKeyPair();
      final privateKey = await _signedPreKeyPair!.extractPrivateKeyBytes();
      await _storage.write(key: 'signed_prekey_private', value: base64Encode(privateKey));
    }
  }

  Future<void> _uploadPublicKeys() async {
    if (_identityKeyPair == null || _signedPreKeyPair == null) return;

    final identityPublic = await _identityKeyPair!.extractPublicKey();
    final signedPublic = await _signedPreKeyPair!.extractPublicKey();

    final onetimeKeys = <Map<String, dynamic>>[];
    for (int i = 0; i < 10; i++) {
      final otp = await _ecdh.newKeyPair();
      final otpPublic = await otp.extractPublicKey();
      onetimeKeys.add({
        'key_id': i,
        'public_key': base64Encode(otpPublic.bytes),
      });
    }

    await _api.post('/encryption/keys', body: {
      'identity_key_public': base64Encode(identityPublic.bytes),
      'signed_prekey_public': base64Encode(signedPublic.bytes),
      'signed_prekey_signature': base64Encode(identityPublic.bytes),
      'onetime_prekeys': onetimeKeys,
    });
  }

  Future<String?> getPreKeyBundle(String userId) async {
    try {
      final response = await _api.get('/encryption/prekey-bundle/$userId');
      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>> encryptMessage(String plaintext, String recipientUserId) async {
    final secretKey = await _deriveSharedSecret(recipientUserId);
    final messageBytes = utf8.encode(plaintext);

    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(messageBytes, secretKey: secretKey, nonce: nonce);

    return secretBox.concatenation();
  }

  Future<String> decryptMessage(List<int> ciphertext, String senderUserId) async {
    final secretKey = await _deriveSharedSecret(senderUserId);
    final secretBox = SecretBox.fromConcatenation(ciphertext, nonceLength: 12, macLength: 16);

    final decryptedBytes = await _aesGcm.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decryptedBytes);
  }

  Future<SecretKey> _deriveSharedSecret(String peerUserId) async {
    if (_sessionKeys.containsKey(peerUserId)) {
      final keyPair = _sessionKeys[peerUserId]!;
      return await _ecdh.sharedSecretKey(keyPair: _identityKeyPair!, remotePublicKey: await keyPair.extractPublicKey());
    }

    final bundleJson = await getPreKeyBundle(peerUserId);
    if (bundleJson != null) {
      final bundle = jsonDecode(bundleJson);
      final remotePublicKey = SimplePublicKey(
        base64Decode(bundle['identity_key_public']),
        type: KeyPairType.p256,
      );
      return await _ecdh.sharedSecretKey(keyPair: _identityKeyPair!, remotePublicKey: remotePublicKey);
    }

    return await _ecdh.sharedSecretKey(
      keyPair: _identityKeyPair!,
      remotePublicKey: await _identityKeyPair!.extractPublicKey(),
    );
  }
}
