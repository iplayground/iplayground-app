import ComposableArchitecture
import Foundation
import Models
import SessionData

@Reducer
package struct TodayFeature {
  @ObservableState
  package struct State: Equatable {
    package var path = StackState<Path.State>()
    @Shared(.day1Sessions) package var day1Sessions: [SessionWrapper] = []
    @Shared(.day2Sessions) package var day2Sessions: [SessionWrapper] = []
    package var selectedDay: Day = .day1
    package var searchText: String = ""

    @SharedReader(.speakers) var speakers: IdentifiedArrayOf<Speaker> = []
    var initialLoaded = false

    package var allSessions: [SessionWrapper] {
      day1Sessions + day2Sessions
    }

    package var currentSessions: [SessionWrapper] {
      let sessions: [SessionWrapper] = {
        switch selectedDay {
        case .day1: day1Sessions
        case .day2: day2Sessions
        }
      }()

      if searchText.isEmpty {
        return sessions
      } else {
        return sessions.filter {
          $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.timeRange.localizedCaseInsensitiveContains(searchText)
            || $0.speaker.localizedCaseInsensitiveContains(searchText)
            || $0.tags?.localizedCaseInsensitiveContains(searchText) ?? false
            || $0.description?.localizedCaseInsensitiveContains(searchText) ?? false
        }
      }
    }

    package var currentSession: SessionWrapper? {
      @Dependency(\.date.now) var now
      return allSessions.first { $0.dateInterval?.contains(now) ?? false }
    }

    package var nextSession: SessionWrapper? {
      @Dependency(\.date.now) var now
      return allSessions.first { ($0.dateInterval?.start ?? .distantFuture) > now }
    }

    package var nextNextSession: SessionWrapper? {
      guard let date = nextSession?.dateInterval?.end else {
        return nil
      }
      return allSessions.first { $0.dateInterval?.start ?? .distantFuture >= date }
    }

    package enum Day: Int, CaseIterable, Identifiable {
      case day1 = 1
      case day2 = 2

      package var id: Int { rawValue }
    }

    package init() {}
  }

  @CasePathable
  package enum Action: Equatable, BindableAction, ComposableArchitecture.ViewAction {
    case binding(BindingAction<State>)
    case path(StackActionOf<Path>)
    case view(ViewAction)
    case navigateToSpeaker(Speaker, hackMDURL: URL?)

    @CasePathable
    package enum ViewAction: Equatable {
      case task
      case tapNowSection
      case tapSession(SessionWrapper)
    }
  }

  package init() {}

  package var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce(core)
      .forEach(\.path, action: \.path)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding(\.day1Sessions):
      if state.initialLoaded == false {
        // 如果現在時間超過第一天的議程的內容，則把selectedDay切成第二天
        if let lastSessionEnd = state.day1Sessions.last?.dateInterval?.end {
          @Dependency(\.date.now) var now
          if now > lastSessionEnd {
            state.selectedDay = .day2
          }
        }

        state.initialLoaded = true
      }

      return .none

    case .binding:
      return .none

    case .path:
      return .none

    case let .view(viewAction):
      switch viewAction {
      case .task:
        return .run { send in
          await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
              @Dependency(\.iPlaygroundDataClient) var client
              let cachedSessions = try await client.fetchSchedules(1, .cacheFirst)
              async let sessions = try await client.fetchSchedules(1, .remote)
              let day1Date = IPlaygroundEvent.day1Date

              let cached = cachedSessions.map {
                SessionWrapper(date: day1Date, session: $0)
              }
              await send(.binding(.set(\.day1Sessions, cached)))

              let remoteSessions = try await sessions.map {
                SessionWrapper(date: day1Date, session: $0)
              }
              if remoteSessions != cached {
                await send(.binding(.set(\.day1Sessions, remoteSessions)))
              }
            }
            group.addTask {
              @Dependency(\.iPlaygroundDataClient) var client
              let cachedSessions = try await client.fetchSchedules(2, .cacheFirst)
              async let sessions = try await client.fetchSchedules(2, .remote)
              let day2Date = IPlaygroundEvent.day2Date

              let cached = cachedSessions.map {
                SessionWrapper(date: day2Date, session: $0)
              }
              await send(.binding(.set(\.day2Sessions, cached)))

              let remoteSessions = try await sessions.map {
                SessionWrapper(date: day2Date, session: $0)
              }
              if remoteSessions != cached {
                await send(.binding(.set(\.day2Sessions, remoteSessions)))
              }
            }
          }
        }

      case .tapNowSection:
        if let currentSession = state.currentSession {
          if state.day1Sessions.first(where: { $0.id == currentSession.id }) != nil {
            state.selectedDay = .day1
          } else if state.day2Sessions.first(where: { $0.id == currentSession.id }) != nil {
            state.selectedDay = .day2
          }
        }
        return .none

      case let .tapSession(session):
        guard let speakerID = session.speakerID else {
          return .none
        }
        return .run { [speakers = state.speakers] send in
          if let speaker = speakers[id: speakerID] {
            await send(.navigateToSpeaker(speaker, hackMDURL: session.hackMDURL))
          } else {
            @Dependency(\.iPlaygroundDataClient) var client
            guard let speaker = try await client.fetchSpeakers(.remote)[id: speakerID] else {
              return
            }
            await send(.navigateToSpeaker(speaker, hackMDURL: session.hackMDURL))
          }
        }
      }

    case let .navigateToSpeaker(speaker, hackMDURL: hackMDURL):
      state.path.append(
        .speaker(.init(speaker: speaker, hackMDURL: hackMDURL)))
      return .none
    }
  }
}
