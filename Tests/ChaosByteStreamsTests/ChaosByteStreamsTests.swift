import Foundation
import Testing

@testable import ChaosByteStreams

let testLines = ["hello", "world"]
let testBytes = testLines.joined(separator: "\n").data(using: .utf8)!

func makeTestBuffer() async -> DataBuffer {
  let buffer = DataBuffer()
  // await buffer.append(testBytes)
  return buffer
}

@Test func testBufferByteStream() async throws {
  let buffer = await makeTestBuffer()
  await buffer.append(testBytes)
  var expected = testLines
  print("a")
  // print(await buffer.data)
  let input = await buffer.makeBytes()
  print("a")
  for await l in input.lines {
    #expect(l == expected.first)
    expected.removeFirst()
  }
  print("a")
  await buffer.finish()
  print("a")
}

@Test func testByteStreamToData() async throws {
  let data = await Data(makeTestBuffer().makeBytes())
  #expect(data == testBytes)
}

@Test func testByteStreamToString() async throws {
  let string = await String(makeTestBuffer().makeBytes())
  #expect(string == testLines.joined(separator: "\n"))
}
