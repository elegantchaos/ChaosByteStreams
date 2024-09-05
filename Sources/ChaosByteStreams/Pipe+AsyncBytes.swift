import Foundation

extension Pipe {
  /// Async sequence of bytes read from the pipe's file handle.
  public struct AsyncBytes: AsyncSequence, Sendable {
    public typealias Element = UInt8

    /// Pipe we're reading from.
    let pipe: Pipe?

    /// Optional file handle to copy read bytes to.
    let forwardHandle: FileHandle?

    /// Make an iterator that reads data from the pipe's file handle
    /// and outputs it as a byte sequence.
    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
      print("makeAsyncIterator")
      let fh = forwardHandle
      return AsyncStream { continuation in
        print("continuation")
        // if we have no pipe, return an empty sequence
        guard let pipe else {
          continuation.finish()
          return
        }

        pipe.fileHandleForReading.readabilityHandler = { @Sendable handle in
          print("readabilityHandler")
          let data = handle.availableData

          guard !data.isEmpty else {
            continuation.finish()
            return
          }

          fh?.write(data)
          for byte in data {
            print(byte)
            continuation.yield(byte)
          }
        }

        continuation.onTermination = { _ in
          pipe.fileHandleForReading.readabilityHandler = nil
        }
      }.makeAsyncIterator()
    }
  }

  /// Return an empty sequence
  public static var noBytes: AsyncBytes { AsyncBytes(pipe: nil, forwardHandle: nil) }

  /// Return byte sequence
  public var bytes: AsyncBytes { AsyncBytes(pipe: self, forwardHandle: nil) }

  public func bytesForwardingTo(_ forwardHandle: FileHandle) -> AsyncBytes {
    AsyncBytes(pipe: self, forwardHandle: forwardHandle)
  }
}
