import ComposableArchitecture
import Dependencies
import Foundation
import Models
import SessionData
import XCTest

@testable import Features

@MainActor
final class SpeakerFeatureTests: XCTestCase {

  func testInitialState() async {
    let speaker = createMockSpeaker()
    let store = TestStore(initialState: SpeakerFeature.State(speaker: speaker, hackMDURL: nil)) {
      SpeakerFeature()
    }

    store.assert {
      $0.speaker = speaker
      $0.hackMDURL = nil
    }
  }

  func testInitialStateWithHackMDURL() async {
    let speaker = createMockSpeaker()
    let hackMDURL = URL(string: "https://hackmd.io/test")!
    let store = TestStore(
      initialState: SpeakerFeature.State(speaker: speaker, hackMDURL: hackMDURL)
    ) {
      SpeakerFeature()
    }

    store.assert {
      $0.speaker = speaker
      $0.hackMDURL = hackMDURL
    }
  }

  func testTaskAction() async {
    let speaker = createMockSpeaker()
    let store = TestStore(initialState: SpeakerFeature.State(speaker: speaker, hackMDURL: nil)) {
      SpeakerFeature()
    }

    await store.send(\.view.task)
  }

  func testTapCopyURL() async {
    let speaker = createMockSpeaker()
    let testURL = URL(string: "https://example.com")!

    let store = TestStore(initialState: SpeakerFeature.State(speaker: speaker, hackMDURL: nil)) {
      SpeakerFeature()
    } withDependencies: {
      $0.pasteboardClient.copy = { string in
        XCTAssertEqual(string, testURL.absoluteString)
      }
    }

    await store.send(\.view.tapCopyURL, testURL)
  }

  // MARK: - Helper Methods

  private func createMockSpeaker(
    id: Int = 1,
    name: String = "Test Speaker",
    title: String? = "Test Title",
    intro: String = "Test introduction",
    photo: URL? = URL(string: "https://example.com/photo.jpg"),
    url: URL? = URL(string: "https://example.com"),
    fb: URL? = URL(string: "https://facebook.com/test"),
    github: URL? = URL(string: "https://github.com/test"),
    linkedin: URL? = URL(string: "https://linkedin.com/test"),
    threads: URL? = URL(string: "https://threads.net/test"),
    x: URL? = URL(string: "https://x.com/test"),
    ig: URL? = URL(string: "https://instagram.com/test")
  ) -> Speaker {
    return Speaker(
      id: id,
      name: name,
      title: title,
      intro: intro,
      photo: photo,
      url: url,
      fb: fb,
      github: github,
      linkedin: linkedin,
      threads: threads,
      x: x,
      ig: ig
    )
  }
}
