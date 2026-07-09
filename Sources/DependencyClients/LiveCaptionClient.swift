import Dependencies
import DependenciesMacros
import Foundation
import Models

@DependencyClient
public struct LiveCaptionClient: Sendable {
  public var captionConnection:
    @Sendable (_ trackNumber: Int) -> AsyncThrowingStream<LiveCaptionStreamAction, Error> = { _ in
      AsyncThrowingStream { _ in }
    }
}

public enum LiveCaptionStreamAction: Equatable, Sendable {
  case connecting
  case connected(expiresAt: Date)
  case disconnected
  case failed(String)
  case event(LiveCaptionServerEvent)
}

extension LiveCaptionClient: TestDependencyKey {
  public static let testValue = Self()

  public static let previewValue = Self(
    captionConnection: { _ in
      AsyncThrowingStream { continuation in
        continuation.yield(.connecting)
        continuation.yield(.connected(expiresAt: Date().addingTimeInterval(3600)))
        continuation.yield(
          .event(
            .control(
              LiveCaptionControlEvent(
                event: .portalStatus,
                status: LiveCaptionPortalStatus.online.rawValue,
                updatedAt: Date()
              ))))
        continuation.yield(
          .event(
            .control(
              LiveCaptionControlEvent(
                event: .sessionStatus,
                status: LiveCaptionSessionStatus.started.rawValue,
                sessionId: "preview",
                updatedAt: Date()
              ))))
        continuation.yield(
          .event(
            .control(
              LiveCaptionControlEvent(
                event: .captionAvailability,
                availableCaptionModes: [.fast, .accurate],
                availableLanguages: [.zhHant, .en, .ja, .ko],
                updatedAt: Date()
              ))))
        continuation.yield(
          .event(
            .caption(
              LiveCaptionItem(
                sessionId: "preview",
                sequence: 1,
                captionMode: .accurate,
                createdAt: Date(),
                captions: [
                  "zh-Hant": "歡迎來到 iPlayground。",
                  "en": "Welcome to iPlayground.",
                  "ja": "iPlayground へようこそ。",
                  "ko": "iPlayground에 오신 것을 환영합니다.",
                ]
              ))))
      }
    }
  )
}

extension DependencyValues {
  public var liveCaptionClient: LiveCaptionClient {
    get { self[LiveCaptionClient.self] }
    set { self[LiveCaptionClient.self] = newValue }
  }
}
