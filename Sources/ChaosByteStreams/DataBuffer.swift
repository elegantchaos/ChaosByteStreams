// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/24.
//  All code (c) 2024 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A buffer that can vend async byte streams of its content.
/// Content can be added to the buffer, and will be forwarded on to any
/// active streams. When the buffer is closed, all active streams will finish.
/// When a new stream is created, any existing data is immediately written to it.
public actor DataBuffer {
  public init() {
  }

  public private(set) var buffer = Data()
  private(set) var continuations: [AsyncStream<UInt8>.Continuation] = []
  private var closed = false

  /// Append data to the buffer.
  /// We'll notify all continuations that new data is available.
  public func append(_ bytes: Data) {
    assert(!bytes.isEmpty)
    buffer.append(bytes)
    for continuation in continuations {
      DataBuffer.sendBytes(bytes, to: continuation)
    }
  }

  /// Close the buffer.
  /// This means that no more data will be added to the buffer.
  /// We'll notify all continuations that the buffer is done, closing
  /// all streams reading from it.
  public func close() {
    closed = true
    for continuation in continuations { continuation.finish() }
    continuations.removeAll()
  }

  /// Add a continuation to the buffer.
  /// We immediately yield all current data in the buffer to the continuation.
  /// If the buffer is already closed, we'll finish the continuation.
  /// If not, when new data is available, we'll yield it to the continuation.
  public nonisolated func registerContinuation(_ continuation: AsyncStream<UInt8>.Continuation) {
    Task.detached { [weak self] in
      if let self {
        await self._registerContinuation(continuation)
        DataBuffer.sendBytes(await self.buffer, to: continuation)
        if await self.closed {
          continuation.finish()
        }
      }
    }
  }

  /// Send bytes to a continuation.
  nonisolated static func sendBytes(_ data: Data, to continuation: AsyncStream<UInt8>.Continuation) {
    for byte in data {
      continuation.yield(byte)
    }
  }

  /// Add a continuation to our array.
  func _registerContinuation(_ continuation: AsyncStream<UInt8>.Continuation) async {
    continuations.append(continuation)
  }

  /// Remove a continuation from our array.
  public nonisolated func unregisterContinuation(_ continuation: AsyncStream<UInt8>.Continuation) {
    // TODO: implement this; may require Boxing each continuation when registering, and then passing back the box so that unregister can pass it in
  }

  /// Return a byte sequence that reads from this buffer.
  public var bytes: AsyncBytes { get async { AsyncBytes(buffer: self) } }

  /// Return a line sequence that reads from this buffer.
  public var lines: AsyncLineSequence<AsyncBytes> { get async { await bytes.lines } }

  /// Wait for the buffer to close, then return it as a `String`.
  public var string: String { get async { await String(bytes) } }

  /// Wait for the buffer to close, then return it as a `Data` object.
  public var data: Data { get async { await Data(bytes) } }

  /// A byte sequence that is empty.
  public static var noBytes: AsyncBytes { AsyncBytes(buffer: nil) }

  /// A byte sequence that reads from a buffer.
  public struct AsyncBytes: AsyncSequence, Sendable {
    public typealias Element = UInt8

    /// Buffer we're reading from.
    let buffer: DataBuffer?

    /// Make an iterator that reads data from the pipe's file handle
    /// and outputs it as a byte sequence.
    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
      return makeStream().makeAsyncIterator()
    }

    public func makeStream() -> AsyncStream<UInt8> {
      let s = AsyncStream<UInt8> { continuation in
        guard let buffer else {
          continuation.finish()
          return
        }
        continuation.onTermination = { termination in
          buffer.unregisterContinuation(continuation)
        }
        buffer.registerContinuation(continuation)
      }
      return s
    }
  }
}
