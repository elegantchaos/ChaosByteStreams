import Foundation
import Testing

@testable import ChaosByteStreams

@Test func testPipeByteStream() async throws {
  let pipe = Pipe()

  var output = ["hello", "world"]
  let input = pipe.bytes
  let handle = pipe.fileHandleForWriting
  handle.write(output.joined(separator: "\n").data(using: .utf8)!)
  handle.closeFile()
  for await l in input.lines {
    #expect(l == output.first)
    output.removeFirst()
  }
}
