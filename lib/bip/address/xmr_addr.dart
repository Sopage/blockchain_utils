/*
  The MIT License (MIT)
  
  Copyright (c) 2021 Emanuele Bellocchia

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
  of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  
  Note: This code has been adapted from its original Python version to Dart.
*/

/*
  The 3-Clause BSD License
  
  Copyright (c) 2023 Mohsen Haydari (MRTNETWORK)
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  
  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions, and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice, this
     list of conditions, and the following disclaimer in the documentation and/or
     other materials provided with the distribution.
  3. Neither the name of the [organization] nor the names of its contributors may be
     used to endorse or promote products derived from this software without
     specific prior written permission.
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
  OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'package:blockchain_utils/base58/base58_xmr.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/compare/compare.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'addr_key_validator.dart';

/// Constants related to Monero (XMR) addresses.
class XmrAddrConst {
  /// The length of the checksum bytes used in XMR addresses.
  static const int checksumByteLen = 4;

  /// The length of payment ID bytes used in XMR addresses.
  static const int paymentIdByteLen = 8;
}

/// Class container for Monero address utility functions.
class _XmrAddrUtils {
  /// Compute checksum in EOS format.
  static List<int> computeChecksum(List<int> payloadBytes) {
    return QuickCrypto.keccack256Hash(payloadBytes)
        .sublist(0, XmrAddrConst.checksumByteLen);
  }

  /// Decode bytes from a Monero address to bytes.
  static List<int> decodeAddr(
    String addr,
    List<int> netVerBytes, {
    List<int>? paymentIdBytes,
  }) {
    final addrDecBytes = Base58XmrDecoder.decode(addr);
    final parts = AddrDecUtils.splitPartsByChecksum(
        addrDecBytes, XmrAddrConst.checksumByteLen);
    final payloadBytes = parts.$1;
    final checksumBytes = parts.$2;

    /// Validate checksum
    AddrDecUtils.validateChecksum(payloadBytes, checksumBytes, computeChecksum);

    /// Validate and remove prefix
    final payloadBytesWithoutPrefix =
        AddrDecUtils.validateAndRemovePrefixBytes(payloadBytes, netVerBytes);

    try {
      /// Validate length without payment ID
      AddrDecUtils.validateBytesLength(
        payloadBytesWithoutPrefix,
        Ed25519KeysConst.pubKeyByteLen * 2,
      );
    } catch (ex) {
      /// Validate length with payment ID
      AddrDecUtils.validateBytesLength(
        payloadBytesWithoutPrefix,
        (Ed25519KeysConst.pubKeyByteLen * 2) + XmrAddrConst.paymentIdByteLen,
      );

      /// Check payment ID
      if (paymentIdBytes == null ||
          paymentIdBytes.length != XmrAddrConst.paymentIdByteLen) {
        throw ArgumentException('Invalid payment ID');
      }

      final paymentIdGotBytes = payloadBytesWithoutPrefix.sublist(
          payloadBytesWithoutPrefix.length - XmrAddrConst.paymentIdByteLen);
      if (!bytesEqual(paymentIdBytes, paymentIdGotBytes)) {
        throw ArgumentException(
            'Invalid payment ID (expected ${BytesUtils.toHexString(paymentIdBytes)}, '
            'got ${BytesUtils.toHexString(paymentIdGotBytes)})');
      }
    }

    /// Validate public spend key
    final pubSpendKeyBytes =
        payloadBytesWithoutPrefix.sublist(0, Ed25519KeysConst.pubKeyByteLen);
    // AddrDecUtils.validatePubKey(pubSpendKeyBytes, Ed25519MoneroPublicKey);

    // Validate public view key
    final pubViewKeyBytes = payloadBytesWithoutPrefix.sublist(
      Ed25519KeysConst.pubKeyByteLen,
      Ed25519KeysConst.pubKeyByteLen * 2,
    );
    // AddrDecUtils.validatePubKey(pubViewKeyBytes, Ed25519MoneroPublicKey);

    return List<int>.from(pubSpendKeyBytes + pubViewKeyBytes);
  }

  static String encodeKey(
    List<int> pubSkey,
    List<int> pubVkey,
    List<int> netVerBytes, {
    List<int>? paymentIdBytes,
  }) {
    if (paymentIdBytes != null &&
        paymentIdBytes.length != XmrAddrConst.paymentIdByteLen) {
      throw ArgumentException('Invalid payment ID length');
    }

    final paymentIdBytesSafe = paymentIdBytes ?? List<int>.from([]);
    final pubSpendKeyObj =
        AddrKeyValidator.validateAndGetEd25519MoneroKey(pubSkey);
    final pubViewKeyObj =
        AddrKeyValidator.validateAndGetEd25519MoneroKey(pubVkey);
    final payloadBytes = List<int>.from(
      netVerBytes +
          pubSpendKeyObj.compressed +
          pubViewKeyObj.compressed +
          paymentIdBytesSafe,
    );

    return Base58XmrEncoder.encode(
        List<int>.from(payloadBytes + computeChecksum(payloadBytes)));
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Monero (XMR) blockchain addresses.
class XmrAddrDecoder implements BlockchainAddressDecoder {
  /// Decodes a Monero (XMR) address.
  ///
  /// Given an XMR address and optional decoding parameters specified in [kwargs],
  /// this method decodes the XMR address and returns the result as a List<int>.
  ///
  /// If decoding parameters are provided, ensure that "net_ver" is a List<int>
  /// representing the network version bytes.
  ///
  /// Parameters:
  /// - addr: The XMR address to decode.
  /// - kwargs: A map of optional decoding parameters, such as "net_ver."
  ///
  /// Returns:
  /// A List<int> containing the decoded address data.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    final List<int> netVerBytes = kwargs["net_ver"];
    return _XmrAddrUtils.decodeAddr(addr, netVerBytes);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Monero (XMR) blockchain addresses.
class XmrAddrEncoder extends BlockchainAddressEncoder {
  /// Encodes a Monero (XMR) public key and view key as an XMR address.
  ///
  /// Given a public key, view key, and optional encoding parameters specified in [kwargs],
  /// this method encodes the public keys as an XMR address and returns the result as a string.
  ///
  /// Ensure that the "net_ver" and "pub_vkey" parameters are provided as List<int> instances.
  ///
  /// Parameters:
  /// - pubKey: The public key to be encoded.
  /// - kwargs: A map of optional encoding parameters, including "net_ver" (network version bytes)
  ///   and "pub_vkey" (public view key).
  ///
  /// Returns:
  /// A string representing the encoded XMR address.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "pub_vkey");
    final List<int> netVerBytes = kwargs["net_ver"];
    final List<int> pubVKey = kwargs["pub_vkey"];
    return _XmrAddrUtils.encodeKey(pubKey, pubVKey, netVerBytes);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Monero (XMR) integrated addresses.
class XmrIntegratedAddrDecoder extends BlockchainAddressDecoder {
  /// Decodes a Monero (XMR) integrated address to extract the public key and view key components.
  ///
  /// Given an XMR address and optional decoding parameters specified in [kwargs],
  /// this method decodes the address to extract the public key and view key components.
  ///
  /// Ensure that the "net_ver" and "payment_id" parameters are provided as List<int> instances.
  ///
  /// Parameters:
  /// - addr: The XMR address to be decoded.
  /// - kwargs: A map of optional decoding parameters, including "net_ver" (network version bytes)
  ///   and "payment_id" (payment ID bytes).
  ///
  /// Returns:
  /// A List<int> representing the decoded public key and view key components.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "payment_id");
    final List<int> netVerBytes = kwargs["net_ver"];
    final List<int> paymentId = kwargs["payment_id"];
    return _XmrAddrUtils.decodeAddr(addr, netVerBytes,
        paymentIdBytes: paymentId);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Monero (XMR) integrated addresses.
class XmrIntegratedAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a Monero (XMR) public key and view key as an XMR address.
  ///
  /// Given a public key, view key, and optional encoding parameters specified in [kwargs],
  /// this method encodes the public keys as an XMR address and returns the result as a string.
  ///
  /// Ensure that the "net_ver" and "pub_vkey", "payment_id" parameters are provided as List<int> instances.
  ///
  /// Parameters:
  /// - pubKey: The public key to be encoded.
  /// - kwargs: A map of optional encoding parameters, including "net_ver" (network version bytes)
  ///   "payment_id" (Payment ID) and "pub_vkey" (public view key).
  ///
  /// Returns:
  /// A string representing the encoded XMR integrated address.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "payment_id");
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "pub_vkey");
    final List<int> netVerBytes = kwargs["net_ver"];
    final List<int> paymentId = kwargs["payment_id"];
    final List<int> pubVKey = kwargs["pub_vkey"];
    return _XmrAddrUtils.encodeKey(pubKey, pubVKey, netVerBytes,
        paymentIdBytes: paymentId);
  }
}
