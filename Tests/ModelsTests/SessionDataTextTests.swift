import Testing

@testable import Models

@Suite("SessionData Text Tests")
struct SessionDataTextTests {
  @Test("Convert HTML line breaks to newlines")
  func convertHTMLLineBreaks() {
    let source = "First<br>Second<br/>Third<br />Fourth<BR>Fifth"

    #expect(source.decodedSessionDataLineBreaks == "First\nSecond\nThird\nFourth\nFifth")
  }

  @Test("Preserve existing newlines")
  func preserveExistingNewlines() {
    let source = "First\nSecond<br>Third"

    #expect(source.decodedSessionDataLineBreaks == "First\nSecond\nThird")
  }
}
