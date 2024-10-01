import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:blockchain_utils/bip/substrate/substrate.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart';

void substrateDeriveTest() {
  /// test from private key and derive
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["private_key"]);
    final coin = SubstrateCoins.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        "${(i["coin"] as String).toLowerCase().replaceAll("_", "")}sr25519");
    Substrate w = Substrate.fromPrivateKey(seed, coin);
    assert(w.publicKey.compressed.toHex() == i["public_key"]);
    assert(w.priveKey.raw.toHex() == i["private_key"]);
    assert(w.publicKey.toAddress == i["address"]);
    final child = List.from(i["child"]);
    for (int c = 0; c < child.length; c++) {
      final childInfo = child[c];
      final path = SubstratePathElem(childInfo["path"]);
      w = w.childKey(path);
      assert(w.publicKey.compressed.toHex() == childInfo["public_key"]);
      assert(w.publicKey.toAddress == childInfo["address"]);
      if (path.isHard) {
        assert(w.priveKey.raw.toHex() == childInfo["private_key"]);
      } else {
        /// for soft derive only first 32 bytes of secret key is equal
        /// and last 32 bytes of secret key (NONCE) generated by random
        final secret = (w.priveKey.privKey as Sr25519PrivateKey).secretKey;
        final testPrive =
            BytesUtils.fromHexString(childInfo["private_key"]).sublist(0, 32);
        assert(BytesUtils.bytesEqual(testPrive, secret.key()), true);
      }
    }
  }

  /// test from seed and derive
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final coin = SubstrateCoins.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        "${(i["coin"] as String).toLowerCase().replaceAll("_", "")}sr25519");
    Substrate w = Substrate.fromSeed(seed, coin);
    assert(w.publicKey.compressed.toHex() == i["public_key"]);
    assert(w.priveKey.raw.toHex() == i["private_key"]);
    assert(w.publicKey.toAddress == i["address"]);
    final child = List.from(i["child"]);
    for (int c = 0; c < child.length; c++) {
      final childInfo = child[c];
      final path = SubstratePathElem(childInfo["path"]);
      w = w.childKey(path);
      assert(w.publicKey.compressed.toHex() == childInfo["public_key"]);
      assert(w.publicKey.toAddress == childInfo["address"]);
      if (path.isHard) {
        assert(w.priveKey.raw.toHex() == childInfo["private_key"]);
      } else {
        /// for soft derive only first 32 bytes of secret key is equal
        /// and last 32 bytes of secret key (NONCE) generated by random
        final secret = (w.priveKey.privKey as Sr25519PrivateKey).secretKey;
        final testPrive =
            BytesUtils.fromHexString(childInfo["private_key"]).sublist(0, 32);
        assert(BytesUtils.bytesEqual(testPrive, secret.key()) == true);
      }
    }
  }
}
