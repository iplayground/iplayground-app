import ComposableArchitecture
import Dependencies
import DependencyClients
import Foundation
import Models
import XCTest

@testable import Features

@MainActor
final class AboutFeatureTests: XCTestCase {

  func testTaskAction() async {
    let store = TestStore(initialState: AboutFeature.State()) {
      AboutFeature()
    }

    await store.send(\.view.task)
    await store.skipReceivedActions()  // Let's skip the exact expectation for concurrent actions

    XCTAssert(!store.state.appVersion.isEmpty)
  }

  func testVersionInfoLoaded() async {
    let store = TestStore(initialState: AboutFeature.State()) {
      AboutFeature()
    }

    await store.send(.versionInfoLoaded(appVersion: "1.2.0", buildNumber: "42")) {
      $0.appVersion = "1.2.0"
      $0.buildNumber = "42"
    }
  }

  func testTapCopyURL() async {
    let testURL = URL(string: "https://iplayground.io")!

    let store = TestStore(initialState: AboutFeature.State()) {
      AboutFeature()
    } withDependencies: {
      $0.pasteboardClient.copy = { text in
        XCTAssertEqual(text, testURL.absoluteString)
      }
    }

    await store.send(\.view.tapCopyURL, testURL)
  }
}
