/// An abstract class 'BlockchainUtilsException' that implements the Exception interface.
/// This class serves as a base for custom exceptions related to blockchain utility operations.
abstract class BlockchainUtilsException implements Exception {
  /// Abstract field to hold the exception message.
  abstract final String message;

  /// Override the 'toString' method to provide a custom string representation of the exception.
  @override
  String toString() {
    return message;
  }
}

/// A specific exception class 'ArgumentException' that extends 'BlockchainUtilsException'.
/// This exception is used to represent errors related to invalid arguments in blockchain utility operations.
class ArgumentException implements BlockchainUtilsException {
  /// Constructor to initialize the exception with a specific message.
  const ArgumentException(this.message);

  /// Final field to store the exception message.
  final String message;

  /// Override the 'toString' method to provide a custom string representation of the exception.
  @override
  String toString() {
    return message;
  }
}

/// Another specific exception class 'MessageException' that extends 'BlockchainUtilsException'.
/// This exception is used to represent errors related to messages in blockchain utility operations.
class MessageException implements BlockchainUtilsException {
  /// Constructor to initialize the exception with a specific message.
  const MessageException(this.message);

  /// Final field to store the exception message.
  final String message;

  /// Override the 'toString' method to provide a custom string representation of the exception.
  @override
  String toString() {
    return message;
  }
}
