import Foundation
import Testing

@testable import ChaosByteStreams

let testLines = ["hello", "world"]
let testBytes = testLines.joined(separator: "\n").data(using: .utf8)!

func makeTestPipeForInput() -> Pipe {
  let pipe = Pipe()
  let handle = pipe.fileHandleForWriting
  handle.write(testBytes)
  handle.closeFile()
  return pipe
}

@Test func testPipeByteStream() async throws {
  let input = makeTestPipeForInput().bytes
  var expected = testLines
  for await l in input.lines {
    #expect(l == expected.first)
    expected.removeFirst()
  }
}

@Test func testStreamToData() async throws {
  let data = await Data(makeTestPipeForInput().bytes)
  #expect(data == testBytes)
}

@Test func testStreamToString() async throws {
  let string = await String(makeTestPipeForInput().bytes)
  #expect(string == testLines.joined(separator: "\n"))
}
