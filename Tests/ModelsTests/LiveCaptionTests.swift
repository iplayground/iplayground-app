import Foundation
import Testing

@testable import Models

@Suite("LiveCaption Tests")
struct LiveCaptionTests {
  @Test("Decode caption event from relay payload")
  func decodeCaptionEvent() throws {
    let data = Data(
      #"{"type":"caption","sessionId":"session-1","sequence":42,"captionMode":"accurate","createdAt":"2026-07-11T04:30:15.123Z","offsetTicks":100,"durationTicks":200,"captions":{"zh-Hant":"大家好","en":"Hello"}}"#
        .utf8
    )

    let event = try LiveCaptionServerEvent.decode(from: data)

    guard case let .caption(caption) = event else {
      Issue.record("Expected a caption event")
      return
    }
    #expect(caption.sessionId == "session-1")
    #expect(caption.sequence == 42)
    #expect(caption.captionMode == .accurate)
    #expect(caption.text(for: .zhHant) == "大家好")
    #expect(caption.createdAt != nil)
  }

  @Test("Decode caption availability control event")
  func decodeCaptionAvailability() throws {
    let data = Data(
      #"{"type":"control","event":"captionAvailability","availableCaptionModes":["fast","accurate"],"availableLanguages":["zh-Hant","en","ja","ko"],"updatedAt":"2026-05-13T09:30:00Z"}"#
        .utf8
    )

    let event = try LiveCaptionServerEvent.decode(from: data)

    guard case let .control(control) = event else {
      Issue.record("Expected a control event")
      return
    }
    #expect(control.event == .captionAvailability)
    #expect(control.availableCaptionModes == [.fast, .accurate])
    #expect(control.availableLanguages == [.zhHant, .en, .ja, .ko])
    #expect(control.updatedAt != nil)
  }
}
