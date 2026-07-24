//
//  MyFeature.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/25.
//

import ComposableArchitecture
import Foundation
import Models

@Reducer
package struct MyFeature: Reducer {
  @ObservableState
  package struct State: Equatable {
    @Shared(.links) package var links: [Link] = []

    package init() {}
  }

  package enum Action: Equatable, BindableAction, ComposableArchitecture.ViewAction {
    case binding(BindingAction<State>)
    case view(ViewAction)
  }

  package enum ViewAction: Equatable {
    case task
    case tapCopyURL(URL)
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

    case let .view(viewAction):
      switch viewAction {
      case .task:
        return .none

      case let .tapCopyURL(url):
        return .run { _ in
          @Dependency(\.pasteboardClient) var pasteboardClient
          pasteboardClient.copy(url.absoluteString)
        }
      }
    }
  }
}
