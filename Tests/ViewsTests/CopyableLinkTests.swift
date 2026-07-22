import SwiftUI
import XCTest

@testable import Views

@MainActor
final class CopyableLinkTests: XCTestCase {
  func testUsesNativeLinkAndForwardsCopyAction() {
    let destination = URL(string: "https://example.com")!
    var didCopy = false
    let copyableLink = CopyableLink(destination: destination) {
      didCopy = true
    } label: {
      Text("Example")
    }

    let _: Link<Text> = copyableLink.link
    XCTAssertEqual(copyableLink.destination, destination)

    copyableLink.performCopy()
    XCTAssertTrue(didCopy)
  }
}
