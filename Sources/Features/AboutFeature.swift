import ComposableArchitecture
import DependencyClients
import Foundation
import Models

@Reducer
package struct AboutFeature {
  @ObservableState
  package struct State: Equatable {
    @SharedReader(.links) package var links: [Link] = []
    package var appVersion: String = ""
    package var buildNumber: String = ""

    package init() {}
  }

  @CasePathable
  package enum Action: Equatable, BindableAction, ComposableArchitecture.ViewAction {
    case binding(BindingAction<State>)
    case view(ViewAction)
    case versionInfoLoaded(appVersion: String, buildNumber: String)

    @CasePathable
    package enum ViewAction: Equatable {
      case task
      case tapCopyURL(URL)
    }
  }

  package init() {}

  package var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce(core)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding:
      return .none

    case let .versionInfoLoaded(appVersion, buildNumber):
      state.appVersion = appVersion
      state.buildNumber = buildNumber
      return .none

    case let .view(viewAction):
      switch viewAction {
      case .task:
        return .run { send in
          await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
              let appVersion =
                Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
              let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
              await send(.versionInfoLoaded(appVersion: appVersion, buildNumber: buildNumber))
            }
          }
        }

      case let .tapCopyURL(url):
        return .run { _ in
          @Dependency(\.pasteboardClient) var pasteboardClient
          pasteboardClient.copy(url.absoluteString)
        }
      }
    }
  }
}
