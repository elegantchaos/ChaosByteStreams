import Foundation

extension String {
  /// Initialise a string from an async byte stream.
  public init<T: AsyncSequence>(_ sequence: T, encoding: String.Encoding = .utf8) async
  where T.Element == UInt8 {
    let data = await Data(sequence)
    self = String(data: data, encoding: encoding) ?? ""
  }
}
