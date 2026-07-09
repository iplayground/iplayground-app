import ComposableArchitecture
import DependencyClients
import Foundation
import Models
import OSLog

private let logger = Logger(subsystem: "Features", category: "LiveCaptionFeature")

@Reducer
package struct LiveCaptionFeature {
  private enum CancelID {
    case stream
  }

  @ObservableState
  package struct State: Equatable {
    package var trackNumber = 1
    package var selectedMode: LiveCaptionMode = .accurate
    package var selectedLanguage: LiveCaptionLanguage = Self.initialLanguage()
    package var availableModes: [LiveCaptionMode] = []
    package var availableLanguages: [LiveCaptionLanguage] = []
    package var portalStatus: LiveCaptionPortalStatus?
    package var sessionStatus: LiveCaptionSessionStatus?
    package var captions: [LiveCaptionItem] = []
    package var connectionState: LiveCaptionConnectionState = .idle
    package var errorMessage: String?
    package var expiresAt: Date?

    package init() {}

    package var displayedCaptions: [LiveCaptionItem] {
      captions.filter { item in
        item.captionMode == selectedMode && item.text(for: selectedLanguage) != nil
      }
    }

    fileprivate static func initialLanguage() -> LiveCaptionLanguage {
      let preferred = Locale.preferredLanguages.first ?? "en"
      if preferred.hasPrefix("zh") { return .zhHant }
      if preferred.hasPrefix("ja") { return .ja }
      if preferred.hasPrefix("ko") { return .ko }
      return .en
    }
  }

  package enum LiveCaptionConnectionState: Equatable, Sendable {
    case idle
    case connecting
    case connected
    case reconnecting
  }

  @CasePathable
  package enum Action: Equatable, ComposableArchitecture.ViewAction {
    case view(ViewAction)
    case streamActionReceived(LiveCaptionStreamAction)

    @CasePathable
    package enum ViewAction: Equatable {
      case task
      case changeTrackNumber(Int)
      case changeCaptionMode(LiveCaptionMode)
      case changeLanguage(LiveCaptionLanguage)
      case reconnect
    }
  }

  package init() {}

  package var body: some ReducerOf<Self> {
    Reduce(core)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case let .streamActionReceived(streamAction):
      return handleStreamAction(streamAction, state: &state)

    case let .view(viewAction):
      switch viewAction {
      case .task:
        return connect(trackNumber: state.trackNumber)

      case let .changeTrackNumber(trackNumber):
        let sanitizedTrackNumber = max(1, trackNumber)
        guard state.trackNumber != sanitizedTrackNumber else { return .none }

        state.trackNumber = sanitizedTrackNumber
        state.portalStatus = nil
        state.sessionStatus = nil
        state.availableModes = []
        state.availableLanguages = []
        state.captions = []
        return connect(trackNumber: sanitizedTrackNumber)

      case let .changeCaptionMode(mode):
        state.selectedMode = mode
        return .none

      case let .changeLanguage(language):
        state.selectedLanguage = language
        return .none

      case .reconnect:
        return connect(trackNumber: state.trackNumber)
      }
    }
  }

  private func handleStreamAction(
    _ streamAction: LiveCaptionStreamAction,
    state: inout State
  ) -> Effect<Action> {
    switch streamAction {
    case .connecting:
      state.connectionState = state.connectionState == .idle ? .connecting : .reconnecting
      state.errorMessage = nil
      return .none

    case let .connected(expiresAt):
      state.connectionState = .connected
      state.errorMessage = nil
      state.expiresAt = expiresAt
      return .none

    case .disconnected:
      state.connectionState = .reconnecting
      return .none

    case let .failed(message):
      state.connectionState = .reconnecting
      state.errorMessage = message
      logger.error("LiveCaption connection failed: \(message)")
      return .none

    case let .event(event):
      switch event {
      case let .control(controlEvent):
        handleControlEvent(controlEvent, state: &state)
        return .none

      case let .caption(caption):
        upsert(caption, state: &state)
        return .none
      }
    }
  }

  private func handleControlEvent(
    _ controlEvent: LiveCaptionControlEvent,
    state: inout State
  ) {
    switch controlEvent.event {
    case .portalStatus:
      state.portalStatus = controlEvent.portalStatus
      if controlEvent.portalStatus == .offline {
        state.sessionStatus = nil
        state.availableModes = []
        state.availableLanguages = []
      }

    case .sessionStatus:
      state.sessionStatus = controlEvent.sessionStatus

    case .captionAvailability:
      state.availableModes = controlEvent.availableCaptionModes ?? []
      state.availableLanguages = controlEvent.availableLanguages ?? []
      reconcileSelections(state: &state)
    }
  }

  private func reconcileSelections(state: inout State) {
    if !state.availableModes.isEmpty && !state.availableModes.contains(state.selectedMode) {
      state.selectedMode =
        state.availableModes.contains(.accurate) ? .accurate : state.availableModes[0]
    }

    if !state.availableLanguages.isEmpty
      && !state.availableLanguages.contains(state.selectedLanguage)
    {
      let preferredLanguage = State.initialLanguage()
      state.selectedLanguage =
        state.availableLanguages.contains(preferredLanguage)
        ? preferredLanguage
        : state.availableLanguages[0]
    }
  }

  private func upsert(_ caption: LiveCaptionItem, state: inout State) {
    if let index = state.captions.firstIndex(where: { $0.id == caption.id }) {
      state.captions[index] = caption
    } else {
      state.captions.append(caption)
    }

    state.captions.sort { lhs, rhs in
      if lhs.sessionId == rhs.sessionId {
        return lhs.sequence < rhs.sequence
      } else {
        return lhs.sessionId < rhs.sessionId
      }
    }
    state.captions = Array(state.captions.suffix(100))
  }

  private func connect(trackNumber: Int) -> Effect<Action> {
    .run { send in
      @Dependency(\.liveCaptionClient) var liveCaptionClient
      let stream = liveCaptionClient.captionConnection(trackNumber)

      do {
        for try await streamAction in stream {
          await send(.streamActionReceived(streamAction))
        }
      } catch {
        await send(.streamActionReceived(.failed(error.localizedDescription)))
      }
    }
    .cancellable(id: CancelID.stream, cancelInFlight: true)
  }
}
