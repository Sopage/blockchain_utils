import 'package:blockchain_utils/crypto/crypto/cdsa/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';

class _NistSignerConst {
  /// The projective ECC point representing the secp256r1 elliptic curve.
  static final ProjectiveECCPoint nist256256 = Curves.generator256;

  /// The length of the digest (or component) in bytes for the secp256r1 curve.
  static final int digestLength = nist256256.curve.baselen;

  /// The order of the secp256R1 elliptic curve.
  static final curveOrder = nist256256.order!;

  /// Half of the order of the secp256R1 elliptic curve.
  static final BigInt orderHalf = curveOrder >> 1;
}

/// Nist256p1Signer Signer class for cryptographic operations, including signing and verification.
///
/// The [Nist256p1Signer] class facilitates the creation of Nist256p1 signatures and
/// provides methods for signing messages, personal messages, and converting to
/// verification keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256R1 elliptic curve.
class Nist256p1Signer {
  const Nist256p1Signer._(this._ecdsaSigningKey);

  final EcdsaSigningKey _ecdsaSigningKey;

  /// Factory method to create a [Nist256p1Signer] from a byte representation of a private key.
  factory Nist256p1Signer.fromKeyBytes(List<int> keyBytes) {
    final signingKey =
        ECDSAPrivateKey.fromBytes(keyBytes, _NistSignerConst.nist256256);
    return Nist256p1Signer._(EcdsaSigningKey(signingKey));
  }

  List<int> _signEcdsa(List<int> digest, {bool hashMessage = true}) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    if (hash.length != _NistSignerConst.digestLength) {
      throw ArgumentException(
          "invalid digest. digest length must be ${_NistSignerConst.digestLength} got ${digest.length}");
    }
    ECDSASignature ecdsaSign = _ecdsaSigningKey.signDigestDeterminstic(
        digest: hash, hashFunc: () => SHA256());
    if (ecdsaSign.s > _NistSignerConst.orderHalf) {
      ecdsaSign = ECDSASignature(
          ecdsaSign.r, _NistSignerConst.curveOrder - ecdsaSign.s);
    }
    final sigBytes =
        ecdsaSign.toBytes(_NistSignerConst.nist256256.curve.baselen);
    final verifyKey = toVerifyKey();
    if (verifyKey.verify(hash, sigBytes)) {
      return ecdsaSign.toBytes(_NistSignerConst.digestLength);
    }

    throw const MessageException(
        'The created signature does not pass verification.');
  }

  /// Signs a message digest using the ECDSA algorithm on the secp256R1 curve.
  ///
  /// Optionally, the message can be hashed before signing.
  ///
  /// Parameters:
  /// - [digest]: The message digest to be signed.
  /// - [hashMessage]: Whether to hash the message before signing (default is true).
  ///
  /// Returns:
  /// - A byte list representing the signature of the message digest.
  ///
  /// Throws:
  /// - [ArgumentException] if the digest length is invalid.
  List<int> sign(List<int> digest, {bool hashMessage = true}) {
    return _signEcdsa(digest, hashMessage: hashMessage);
  }

  /// Converts the [Nist256p1Signer] to a [Nist256p1Verifier] for verification purposes.
  ///
  /// Returns:
  /// - A [Nist256p1Verifier] representing the verification key.
  Nist256p1Verifier toVerifyKey() {
    return Nist256p1Verifier.fromKeyBytes(
        _ecdsaSigningKey.privateKey.publicKey.toBytes());
  }
}

/// [Nist256p1Verifier] class for cryptographic operations, including signature verification.
///
/// The [Nist256p1Verifier] class allows the verification of Nist256p1 signatures and
/// public keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256r1 elliptic curve.
class Nist256p1Verifier {
  final ECDSAVerifyKey edsaVerifyKey;

  Nist256p1Verifier._(this.edsaVerifyKey);

  /// Factory method to create a [Nist256p1Verifier] from a byte representation of a public key.
  factory Nist256p1Verifier.fromKeyBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
        curve: _NistSignerConst.nist256256.curve, data: keyBytes, order: null);
    final verifyingKey = ECDSAPublicKey(_NistSignerConst.nist256256, point);
    return Nist256p1Verifier._(ECDSAVerifyKey(verifyingKey));
  }
  bool _verifyEcdsa(List<int> digest, List<int> sigBytes) {
    final signature =
        ECDSASignature.fromBytes(sigBytes, _NistSignerConst.nist256256);
    return edsaVerifyKey.verify(signature, digest);
  }

  /// Verifies a Nist256p1 signature against a message digest.
  ///
  /// Parameters:
  /// - [message]: The message digest.
  /// - [signature]: The signature bytes.
  ///
  /// Returns:
  /// - True if the signature is valid, false otherwise.
  bool verify(List<int> message, List<int> signature,
      {bool hashMessage = false}) {
    if (hashMessage) {
      message = QuickCrypto.sha256Hash(message);
    }
    return _verifyEcdsa(message, signature);
  }
}
