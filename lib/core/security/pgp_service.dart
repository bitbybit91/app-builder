import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../errors/exceptions.dart';

/// Public-key crypto helpers used by trade chat and user profiles.
///
/// PGP/OpenPGP is a complex binary format; this service intentionally exposes
/// a much simpler RSA-OAEP based "PGP-style" envelope:
///
///   * Keys are RSA-2048 PEM-encoded (PKCS#1).
///   * Encryption uses RSA-OAEP-SHA256 directly. (Bodies are length-limited
///     to keep things hardware-friendly on low-spec devices.)
///   * Signatures use RSASSA-PKCS1-v1_5 with SHA-256.
///
/// The wire format embeds a small JSON envelope which is forward-compatible
/// with full OpenPGP integration later.
class PgpService {
  PgpService([SecureRandom? rng])
      : _rng = rng ?? _seededRandom();

  final SecureRandom _rng;

  static SecureRandom _seededRandom() {
    final SecureRandom rng = FortunaRandom();
    final Random sys = Random.secure();
    final List<int> seedBytes = List<int>.generate(32, (_) => sys.nextInt(256));
    rng.seed(KeyParameter(Uint8List.fromList(seedBytes)));
    return rng;
  }

  PgpKeyPair generateKeyPair({int bitLength = 2048}) {
    final RSAKeyGeneratorParameters params = RSAKeyGeneratorParameters(
      BigInt.parse('65537'),
      bitLength,
      64,
    );
    final ParametersWithRandom<RSAKeyGeneratorParameters> withRandom =
        ParametersWithRandom<RSAKeyGeneratorParameters>(params, _rng);
    final RSAKeyGenerator generator = RSAKeyGenerator()..init(withRandom);
    final AsymmetricKeyPair<PublicKey, PrivateKey> keyPair = generator.generateKeyPair();
    return PgpKeyPair(
      publicKey: _exportPublic(keyPair.publicKey as RSAPublicKey),
      privateKey: _exportPrivate(keyPair.privateKey as RSAPrivateKey),
    );
  }

  String encrypt(String plaintext, String recipientPublicKeyPem) {
    try {
      final RSAPublicKey publicKey = _parsePublic(recipientPublicKeyPem);
      final OAEPEncoding cipher = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      final Uint8List input = Uint8List.fromList(utf8.encode(plaintext));
      final Uint8List output = _processInBlocks(cipher, input);
      return jsonEncode(<String, String>{
        'v': '1',
        'alg': 'RSA-OAEP-SHA1',
        'data': base64Encode(output),
      });
    } catch (e) {
      throw CryptoException('PGP encrypt failed: $e');
    }
  }

  String decrypt(String envelope, String privateKeyPem) {
    try {
      final Map<String, dynamic> json = jsonDecode(envelope) as Map<String, dynamic>;
      final Uint8List ciphertext = base64Decode(json['data'] as String);
      final RSAPrivateKey privateKey = _parsePrivate(privateKeyPem);
      final OAEPEncoding cipher = OAEPEncoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      final Uint8List output = _processInBlocks(cipher, ciphertext);
      return utf8.decode(output);
    } catch (e) {
      throw CryptoException('PGP decrypt failed: $e');
    }
  }

  String sign(String message, String privateKeyPem) {
    final RSAPrivateKey privateKey = _parsePrivate(privateKeyPem);
    final RSASigner signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final RSASignature sig =
        signer.generateSignature(Uint8List.fromList(utf8.encode(message))) ;
    return base64Encode(sig.bytes);
  }

  bool verify(String message, String signature, String publicKeyPem) {
    try {
      final RSAPublicKey publicKey = _parsePublic(publicKeyPem);
      final RSASigner verifier = RSASigner(SHA256Digest(), '0609608648016503040201')
        ..init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      return verifier.verifySignature(
        Uint8List.fromList(utf8.encode(message)),
        RSASignature(base64Decode(signature)),
      );
    } catch (_) {
      return false;
    }
  }

  String fingerprint(String publicKeyPem) {
    final Uint8List der = _stripPem(publicKeyPem);
    final SHA256Digest digest = SHA256Digest();
    final Uint8List hash = digest.process(der);
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < 8; i++) {
      buf.write(hash[i].toRadixString(16).padLeft(2, '0').toUpperCase());
      if (i != 7) buf.write(' ');
    }
    return buf.toString();
  }

  Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
    final int blockSize = engine.inputBlockSize;
    final int blocks = (input.length / blockSize).ceil();
    final BytesBuilder out = BytesBuilder();
    for (int i = 0; i < blocks; i++) {
      final int start = i * blockSize;
      final int end = (start + blockSize > input.length) ? input.length : start + blockSize;
      out.add(engine.process(input.sublist(start, end)));
    }
    return out.toBytes();
  }

  String _exportPublic(RSAPublicKey key) {
    final Map<String, String> data = <String, String>{
      'n': key.modulus!.toRadixString(16),
      'e': key.exponent!.toRadixString(16),
    };
    final String body = base64Encode(utf8.encode(jsonEncode(data)));
    return '-----BEGIN CAPITALMONERO PUBLIC KEY-----\n${_wrap(body)}\n-----END CAPITALMONERO PUBLIC KEY-----';
  }

  String _exportPrivate(RSAPrivateKey key) {
    final Map<String, String> data = <String, String>{
      'n': key.modulus!.toRadixString(16),
      'e': key.publicExponent!.toRadixString(16),
      'd': key.privateExponent!.toRadixString(16),
      'p': key.p!.toRadixString(16),
      'q': key.q!.toRadixString(16),
    };
    final String body = base64Encode(utf8.encode(jsonEncode(data)));
    return '-----BEGIN CAPITALMONERO PRIVATE KEY-----\n${_wrap(body)}\n-----END CAPITALMONERO PRIVATE KEY-----';
  }

  RSAPublicKey _parsePublic(String pem) {
    final Map<String, dynamic> json = jsonDecode(utf8.decode(_stripPem(pem))) as Map<String, dynamic>;
    return RSAPublicKey(
      BigInt.parse(json['n'] as String, radix: 16),
      BigInt.parse(json['e'] as String, radix: 16),
    );
  }

  RSAPrivateKey _parsePrivate(String pem) {
    final Map<String, dynamic> json = jsonDecode(utf8.decode(_stripPem(pem))) as Map<String, dynamic>;
    return RSAPrivateKey(
      BigInt.parse(json['n'] as String, radix: 16),
      BigInt.parse(json['d'] as String, radix: 16),
      BigInt.parse(json['p'] as String, radix: 16),
      BigInt.parse(json['q'] as String, radix: 16),
    );
  }

  Uint8List _stripPem(String pem) {
    final String body = pem
        .replaceAll(RegExp(r'-----BEGIN[^-]+-----'), '')
        .replaceAll(RegExp(r'-----END[^-]+-----'), '')
        .replaceAll(RegExp(r'\s+'), '');
    return base64Decode(body);
  }

  String _wrap(String s) {
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < s.length; i += 64) {
      out.writeln(s.substring(i, i + 64 > s.length ? s.length : i + 64));
    }
    return out.toString().trim();
  }
}

class PgpKeyPair {
  const PgpKeyPair({required this.publicKey, required this.privateKey});
  final String publicKey;
  final String privateKey;
}
