import ComposableArchitecture
import Features
import Models
import XCTest

@MainActor
final class LiveCaptionFeatureTests: XCTestCase {
  func testStartingNewSessionClearsPreviousCaptions() async {
    var state = LiveCaptionFeature.State()
    state.activeSessionID = "old-session"
    state.sessionStatus = .started
    state.captions = [caption(sessionID: "old-session", sequence: 1)]

    let store = TestStore(initialState: state) {
      LiveCaptionFeature()
    }

    let event = LiveCaptionControlEvent(
      event: .sessionStatus,
      status: LiveCaptionSessionStatus.started.rawValue,
      sessionId: "new-session"
    )

    await store.send(.streamActionReceived(.event(.control(event)))) {
      $0.activeSessionID = "new-session"
      $0.sessionStatus = .started
      $0.captions = []
    }
  }

  func testCaptionFromInactiveSessionIsIgnored() async {
    var state = LiveCaptionFeature.State()
    state.activeSessionID = "current-session"

    let store = TestStore(initialState: state) {
      LiveCaptionFeature()
    }

    await store.send(
      .streamActionReceived(
        .event(.caption(caption(sessionID: "previous-session", sequence: 1)))
      )
    )
  }

  func testPortalOfflineClearsSessionAndCaptions() async {
    var state = LiveCaptionFeature.State()
    state.portalStatus = .online
    state.sessionStatus = .started
    state.activeSessionID = "current-session"
    state.availableModes = [.accurate]
    state.availableLanguages = [.zhHant]
    state.captions = [caption(sessionID: "current-session", sequence: 1)]

    let store = TestStore(initialState: state) {
      LiveCaptionFeature()
    }

    let event = LiveCaptionControlEvent(
      event: .portalStatus,
      status: LiveCaptionPortalStatus.offline.rawValue
    )

    await store.send(.streamActionReceived(.event(.control(event)))) {
      $0.portalStatus = .offline
      $0.sessionStatus = nil
      $0.activeSessionID = nil
      $0.availableModes = []
      $0.availableLanguages = []
      $0.captions = []
    }
  }

  func testAvailabilityFallsBackToSupportedSelections() async {
    var state = LiveCaptionFeature.State()
    state.selectedMode = .fast
    state.selectedLanguage = .ja

    let store = TestStore(initialState: state) {
      LiveCaptionFeature()
    }

    let event = LiveCaptionControlEvent(
      event: .captionAvailability,
      availableCaptionModes: [.accurate],
      availableLanguages: [.en, .ko]
    )

    await store.send(.streamActionReceived(.event(.control(event)))) {
      $0.availableModes = [.accurate]
      $0.availableLanguages = [.en, .ko]
      $0.selectedMode = .accurate
      $0.selectedLanguage = .en
      $0.didFallbackSelection = true
    }
  }

  func testCaptionsAreOrderedAndUpdatedBySequence() async {
    var state = LiveCaptionFeature.State()
    state.activeSessionID = "current-session"

    let store = TestStore(initialState: state) {
      LiveCaptionFeature()
    }

    let second = caption(sessionID: "current-session", sequence: 2, text: "第二句")
    let first = caption(sessionID: "current-session", sequence: 1, text: "第一句")
    let revisedFirst = caption(sessionID: "current-session", sequence: 1, text: "第一句修正")

    await store.send(.streamActionReceived(.event(.caption(second)))) {
      $0.captions = [second]
    }
    await store.send(.streamActionReceived(.event(.caption(first)))) {
      $0.captions = [first, second]
    }
    await store.send(.streamActionReceived(.event(.caption(revisedFirst)))) {
      $0.captions = [revisedFirst, second]
    }
  }

  func testLanguageSheetSelection() async {
    let store = TestStore(initialState: LiveCaptionFeature.State()) {
      LiveCaptionFeature()
    }

    await store.send(.view(.showLanguageSheet)) {
      $0.isShowingLanguageSheet = true
    }
    await store.send(.view(.changeLanguage(.ja))) {
      $0.selectedLanguage = .ja
      $0.isShowingLanguageSheet = false
    }
  }

  func testTrackNumberIsAlwaysPositive() async {
    var state = LiveCaptionFeature.State()
    state.trackNumber = 2
    state.activeSessionID = "current-session"
    state.captions = [caption(sessionID: "current-session", sequence: 1)]

    let store = TestStore(initialState: state) {
      LiveCaptionFeature()
    } withDependencies: {
      $0.liveCaptionClient.captionConnection = { _ in
        AsyncThrowingStream { continuation in
          continuation.finish()
        }
      }
    }

    await store.send(.view(.changeTrackNumber(0))) {
      $0.trackNumber = 1
      $0.activeSessionID = nil
      $0.captions = []
    }
    await store.finish()
  }

  private func caption(
    sessionID: String,
    sequence: Int,
    mode: LiveCaptionMode = .accurate,
    language: LiveCaptionLanguage = .zhHant,
    text: String = "字幕"
  ) -> LiveCaptionItem {
    LiveCaptionItem(
      sessionId: sessionID,
      sequence: sequence,
      captionMode: mode,
      captions: [language.rawValue: text]
    )
  }
}
