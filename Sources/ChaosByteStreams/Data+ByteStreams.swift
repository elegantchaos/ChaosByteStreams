import Foundation

/// Byte stream extensions for data.
extension Data {
  /// Initialise a data buffer from an async stream of bytes.
  /// Consumes the entire sequence.
  public init<T: AsyncSequence>(_ sequence: T) async where T.Element == UInt8 {
    var data = Data()
    do {
      for try await byte in sequence {
        data.append(byte)
      }
    } catch {

    }

    self = data
  }
}
