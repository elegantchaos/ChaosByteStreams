import Foundation
import Testing

@testable import ChaosByteStreams

let testLines = ["hello", "world"]
let testBytes = testLines.joined(separator: "\n").data(using: .utf8)!

func makeTestBuffer() async -> DataBuffer {
  let buffer = DataBuffer()
  DispatchQueue.global(qos: .background).async {
    Task {
      await buffer.append(testBytes)
      try? await Task.sleep(nanoseconds: 100)
      await buffer.finish()
    }
  }
  return buffer
}

@Test func testBufferByteStream() async throws {
  let buffer = await makeTestBuffer()
  var expected = testLines
  let input = await buffer.makeBytes()
  
  print("reading from input")
  for await l in input.lines {
    #expect(l == expected.first)
    expected.removeFirst()
  }
}

@Test func testByteStreamToData() async throws {
  let data = await Data(makeTestBuffer().makeBytes())
  #expect(data == testBytes)
}

@Test func testByteStreamToString() async throws {
  let string = await String(makeTestBuffer().makeBytes())
  #expect(string == testLines.joined(separator: "\n"))
}
