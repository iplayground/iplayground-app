//
//  SpeakerFeature.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/21.
//

import ComposableArchitecture
import Foundation
import Models

@Reducer
package struct SpeakerFeature {
  @ObservableState
  package struct State: Equatable {
    package var speaker: Speaker
    package var hackMDURL: URL?

    package init(speaker: Speaker, hackMDURL: URL?) {
      self.speaker = speaker
      self.hackMDURL = hackMDURL
    }
  }

  @CasePathable
  package enum Action: Equatable, BindableAction, ComposableArchitecture.ViewAction {
    case view(ViewAction)
    case binding(BindingAction<State>)

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
