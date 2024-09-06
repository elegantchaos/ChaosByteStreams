# ChaosByteStreams

Miscellaneous utilities for working with async byte streams.

Adds ways to:

## Data

Adds a convenience initialiser to read an entire `AsyncStream<UInt8>`
stream into a `Data` object

## String

Adds a convenience initialiser to read  an entire `AsyncStream<UInt8>`
stream into a `String` object

## DataBuffer

Adds a `DataBuffer` class which can have `Data` appended to it in a
thread-safe manner, and which can vend one or more `AsyncStream<UInt8>`
streams that can be used to read bytes from it asynchronously.

Any streams made in this way stay alive until `close()` is called on the
buffer backing them.
