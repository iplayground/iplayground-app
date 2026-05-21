//
//  MyView.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/25.
//

import ComposableArchitecture
import Features
import Models
import SwiftUI

@ViewAction(for: MyFeature.self)
struct MyView: View {
  @Bindable package var store: StoreOf<MyFeature>
  @Environment(\.iPlaygroundTheme) private var theme

  var body: some View {
    NavigationStack {
      List {
        personalLinksSection
      }
      .navigationTitle(String(localized: "我的", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .task {
        send(.task)
      }
    }
  }

  @ViewBuilder
  private var personalLinksSection: some View {
    Section {
      ForEach(personalLinks) { link in
        urlMenuButton(link: link)
      }
    }
  }

  @ViewBuilder
  private func urlMenuButton(link: Models.Link) -> some View {
    Menu(
      content: {
        copyURLButton(url: link.url)
      },
      label: {
        HStack {
          if let iconName = link.icon {
            Label(link.localizedTitle, systemImage: iconName)
          } else {
            Text(link.localizedTitle)
          }
          Spacer()
          Image(systemName: "arrow.up.right.square")
            .foregroundStyle(theme.tint)
        }
      },
      primaryAction: {
        send(.tapURL(link.url))
      }
    )
  }

  @ViewBuilder
  private func copyURLButton(url: URL) -> some View {
    Button(
      action: {
        send(.tapCopyURL(url))
      },
      label: {
        Label(String(localized: "拷貝", bundle: .module), systemImage: "document.on.document")
      }
    )
  }

  private var personalLinks: [Models.Link] {
    store.links.filter { link in
      link.type == .personal
    }
  }
}

#Preview {
  MyView(store: .init(initialState: .init(), reducer: { MyFeature() }))
}
