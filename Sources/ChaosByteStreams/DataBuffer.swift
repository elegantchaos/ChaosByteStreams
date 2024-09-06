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
    assert(!bytes.isEmpty)
    data.append(bytes)
    for continuation in continuations {
      DataBuffer.sendBytes(bytes, to: continuation)
    }
  }
  
  /// Finish the buffer.
  /// This means that no more data will be added to the buffer.
  /// We'll notify all continuations that the buffer is done.
  func finish() {
    for continuation in continuations { continuation.finish() }
    continuations.removeAll()
  }
  
  /// Add a continuation to the buffer.
  /// We immediately yield all current data in the buffer to the continuation.
  /// When new data is available, we'll yield it to the continuation.
  ///
  nonisolated func registerContinuation(_ continuation: AsyncStream<UInt8>.Continuation) {
    Task.detached { [weak self] in
      await self?._registerContinuation(continuation)
      if let data = await self?.data {
        DataBuffer.sendBytes(data, to: continuation)
      }
    }
  }
  
  nonisolated static func sendBytes(_ data: Data, to continuation: AsyncStream<UInt8>.Continuation) {
    for byte in data {
      continuation.yield(byte)
    }
  }
  
  func _registerContinuation(_ continuation: AsyncStream<UInt8>.Continuation) async {
    continuations.append(continuation)
  }
  
  nonisolated func unregisterContinuation(_ continuation: AsyncStream<UInt8>.Continuation) {
    // TODO: implement this; may require allocating an id for each continuation when registering, and then passing it back to unregister
  }
  
  /// Return a byte sequence that reads from this buffer.
  func makeBytes() -> AsyncBytes { AsyncBytes(buffer: self) }
  
  var bytes: AsyncBytes { get async { AsyncBytes(buffer: self) }}
  
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
