import 'package:blockchain_utils/exception/exception.dart';

/// An exception class for errors related to SS58 address checksum validation.
///
/// The [message] field can contain additional information about the error.
class SS58ChecksumError implements BlockchainUtilsException {
  final String message;

  /// Creates a new [SS58ChecksumError] with an optional [message].
  const SS58ChecksumError(this.message);

  @override
  String toString() {
    return message;
  }
}
