import ComposableArchitecture
import Models

@Reducer
package struct AppFeature {
  @ObservableState
  package struct State: Equatable {
    package var home = HomeFeature.State()

    package init() {}
  }

  package enum Action: Equatable {
    case home(HomeFeature.Action)
  }

  package init() {}

  package var body: some ReducerOf<Self> {
    Scope(state: \.home, action: \.home) {
      HomeFeature()
    }
    Reduce(core)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .home:
      return .none
    }
  }
}
