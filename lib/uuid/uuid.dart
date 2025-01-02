/// UUID Library
///
/// This library provides utility functions and classes for working with
/// Universally Unique Identifiers (UUIDs). UUIDs are commonly used in
/// various applications to uniquely identify entities or resources.
///
/// The `UUID` class within this library allows for the generation UUID V4

library;

import 'dart:math' as math;

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

class UUID {
  /// Generates a version 4 (random) UUID (Universally Unique Identifier).
  ///
  /// This method generates a random UUIDv4 following the RFC 4122 standard.
  /// UUIDs generated by this method are suitable for unique identifiers in various
  /// applications. UUIDv4s are 128-bit long and typically represented as a
  /// hexadecimal string separated by hyphens.
  ///
  /// Returns:
  /// A random UUIDv4 as a string in the format "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".
  static String generateUUIDv4() {
    final random = math.Random.secure();

    /// Generate random bytes for the UUIDv4.
    final bytes = List<int>.generate(16, (i) {
      if (i == 6) {
        return (random.nextInt(16) & 0x0f) | 0x40;
      } else if (i == 8) {
        return (random.nextInt(4) & 0x03) | 0x08;
      } else {
        return random.nextInt(256);
      }
    });

    /// Set the 6th high-order bit of the 6th byte to indicate version 4.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    /// Set the 7th high-order bit of the 8th byte to indicate variant RFC4122.
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    /// Convert bytes to a hexadecimal string with hyphen-separated groups.
    final List<String> hexBytes =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).toList();

    return '${hexBytes.sublist(0, 4).join('')}-${hexBytes.sublist(4, 6).join('')}-'
        '${hexBytes.sublist(6, 8).join('')}-${hexBytes.sublist(8, 10).join('')}-'
        '${hexBytes.sublist(10).join('')}';
  }

  /// Converts a UUID string to a binary buffer.
  ///
  /// This method takes a UUID string in the format
  /// "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", removes hyphens, and converts it
  /// to a binary buffer of 16 bytes. The binary buffer representation of a UUID
  /// can be useful for certain operations, such as storage or transmission.
  ///
  /// Parameters:
  /// - [uuidString]: The UUID string to convert to a binary buffer.
  ///
  /// Returns:
  /// A binary buffer (`List<int>`) representing the UUID.
  static List<int> toBuffer(String uuidString, {bool validate = true}) {
    if (validate && !isValidUUIDv4(uuidString)) {
      throw ArgumentException("invalid uuid string.",
          details: {"uuid": uuidString});
    }
    final buffer = List<int>.filled(16, 0);

    /// Remove dashes and convert the hexadecimal string to bytes
    final cleanUuidString = uuidString.replaceAll('-', '');
    final bytes = BytesUtils.fromHexString(cleanUuidString);

    /// Copy the bytes into the buffer
    for (var i = 0; i < 16; i++) {
      buffer[i] = bytes[i];
    }

    return buffer;
  }

  /// Converts a binary buffer to a UUIDv4 string.
  ///
  /// This method takes a binary buffer of 16 bytes and converts it into a
  /// UUIDv4 string in the format "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx". The
  /// UUIDv4 string is commonly used to represent unique identifiers.
  ///
  /// Parameters:
  /// - [buffer]: The binary buffer (`List<int>`) representing the UUID.
  ///
  /// Returns:
  /// A UUIDv4 string.
  ///
  /// Throws:
  /// - [ArgumentException] if the input buffer's length is not 16 bytes, as UUIDv4
  ///   buffers must be exactly 16 bytes long.
  ///
  /// Note:
  /// This method assumes that the input buffer contains valid UUIDv4 data.
  static String fromBuffer(List<int> buffer) {
    if (buffer.length != 16) {
      throw const ArgumentException(
          'Invalid buffer length. UUIDv4 buffers must be 16 bytes long.');
    }

    final List<String> hexBytes =
        buffer.map((byte) => byte.toRadixString(16).padLeft(2, '0')).toList();

    /// Insert dashes at appropriate positions to form a UUIDv4 string
    return '${hexBytes.sublist(0, 4).join('')}-${hexBytes.sublist(4, 6).join('')}-${hexBytes.sublist(6, 8).join('')}-${hexBytes.sublist(8, 10).join('')}-${hexBytes.sublist(10).join('')}';
  }

  /// Regular expression pattern for UUIDv4
  static final _pattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// Validates whether a string is a valid UUIDv4.
  static bool isValidUUIDv4(String uuid) {
    /// Check if the input string matches the pattern
    return _pattern.hasMatch(uuid);
  }
}
