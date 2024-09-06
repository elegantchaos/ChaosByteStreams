// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/24.
//  All code (c) 2024 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public actor DataBuffer {
  var data = Data()
  var continuations: [AsyncStream<UInt8>.Continuation] = []

  /// Append data to the buffer.
  /// We'll notify all continuations that new data is available.
  func append(_ bytes: Data) {
    print("append")
    assert(!bytes.isEmpty)
    data.append(bytes)
    for continuation in continuations {
      for byte in bytes { continuation.yield(byte) }
    }
  }

  /// Finish the buffer.
  /// This means that no more data will be added to the buffer.
  /// We'll notify all continuations that the buffer is done.
  func finish() {
    print("finish")
    for continuation in continuations { continuation.finish() }
    continuations.removeAll()
  }

  /// Add a continuation to the buffer.
  /// We immediately yield all current data in the buffer to the continuation.
  /// When new data is available, we'll yield it to the continuation.
  func registerContinuation(_ continuation: AsyncStream<UInt8>.Continuation) async {
    print("register")
    continuations.append(continuation)
    if !data.isEmpty {
      let d = data
      print("sending existing data")
      for byte in d {
        print(String(format: "%c", byte))
        continuation.yield(byte)
      }
      print("sent")
    }
  }

  func removeContinuation(_ continuation: AsyncStream<UInt8>.Continuation) {
    print("remove")
  }

  /// Return a byte sequence that reads from this buffer.
  func makeBytes() -> AsyncBytes { AsyncBytes(buffer: self) }

  /// A byte sequence that is empty.
  static var noBytes: AsyncBytes { AsyncBytes(buffer: nil) }

  /// A byte sequence that reads from a buffer.
  public struct AsyncBytes: AsyncSequence, Sendable {
    public typealias Element = UInt8

    /// Buffer we're reading from.
    let buffer: DataBuffer?

    /// Make an iterator that reads data from the pipe's file handle
    /// and outputs it as a byte sequence.
    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
      print("make")
      return AsyncStream { continuation in
        guard let buffer else {
          continuation.finish()
          return
        }
        continuation.onTermination = { termination in
          Task { await buffer.removeContinuation(continuation) }
        }
        Task.detached {
          await buffer.registerContinuation(continuation)
          print("registered")
        }
      }.makeAsyncIterator()
    }
  }
}
