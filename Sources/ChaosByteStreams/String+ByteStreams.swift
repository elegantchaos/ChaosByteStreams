import Foundation

/// Byte stream extensions for strings.
extension String {
  /// Initialise from an `AsyncSequence` of bytes.
  /// Consumes the entire sequence and waits for it to end.
  public init<T: AsyncSequence>(_ sequence: T, encoding: String.Encoding = .utf8) async
  where T.Element == UInt8 {
    let data = await Data(sequence)
    self = String(data: data, encoding: encoding) ?? ""
  }
}
