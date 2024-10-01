import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';

void signTron() {
  final signer = TronSigner.fromKeyBytes(BytesUtils.fromHexString(
      "43985273a3d94eb753fe6acfd7003e88254effce1eb53e2e97b8522558a98038"));
  final message = utf8.encode("message");
  final sign = signer.signProsonalMessage(message);
  final verify = signer.toVerifyKey().verifyPersonalMessage(message, sign);
  assert(BytesUtils.toHexString(sign) ==
      "fde00bc33d78109bc61de314c1c0526a047e22a2aaae473ca84b32d8aa35ed3e03720e05d614087e3d8c6fae63879755b32aa08818a2d4de66fee1a617a971671b");
  assert(verify, true);
  final publicKey = TronVerifier.getPublicKey(message, sign);
  assert(
      BytesUtils.bytesEqual(publicKey?.toBytes(),
          signer.toVerifyKey().edsaVerifyKey.publicKey.toBytes()),
      true);
}
