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
      .navigationTitle(Text(AppNavigationTitle.activity.localizedResource))
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
    CopyableLink(destination: link.url) {
      send(.tapCopyURL(link.url))
    } label: {
      HStack {
        if let iconName = link.icon {
          Label {
            MyLinkTitle(title: link.localizedTitle)
          } icon: {
            Image(systemName: iconName)
          }
        } else {
          MyLinkTitle(title: link.localizedTitle)
        }
        Spacer()
        Image(systemName: "arrow.up.right.square")
          .foregroundStyle(theme.tint)
      }
    }
  }

  private var personalLinks: [Models.Link] {
    store.links.filter { link in
      link.type == .personal
    }
  }
}

struct MyLinkTitle: View {
  let title: String

  var body: some View {
    Text(title)
      .multilineTextAlignment(.leading)
  }
}

#Preview {
  MyView(store: .init(initialState: .init(), reducer: { MyFeature() }))
}
