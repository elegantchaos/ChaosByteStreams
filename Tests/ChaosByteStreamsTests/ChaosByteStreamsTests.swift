import Foundation
import Testing

@testable import ChaosByteStreams

let testLines = ["hello", "world"]
let testBytes = testLines.joined(separator: "\n").data(using: .utf8)!

/// Make a test buffer and write data to it on a background thread.
/// We write the data byte by byte, with pauses between each one.
func makeTestBuffer() async -> DataBuffer {
  let buffer = DataBuffer()
  DispatchQueue.global(qos: .background).async {
    Task.detached {
      for byte in testBytes {
        await buffer.append(Data([byte]))
        try? await Task.sleep(nanoseconds: 10)
      }
      await buffer.finish()
    }
  }
  return buffer
}

@Test func testBufferByteStream() async throws {
  let buffer = await makeTestBuffer()
  var expected = testLines
  let input = await buffer.bytes
  
  for await l in input.lines {
    #expect(l == expected.first)
    expected.removeFirst()
  }
}

@Test func testByteStreamToData() async throws {
  let data = await Data(makeTestBuffer().bytes)
  #expect(data == testBytes)
}

@Test func testByteStreamToString() async throws {
  let string = await String(makeTestBuffer().bytes)
  #expect(string == testLines.joined(separator: "\n"))
}
