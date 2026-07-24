import ComposableArchitecture
import Features
import Models
import SwiftUI

package struct AppView: View {
  let store: StoreOf<AppFeature>
  @State private var themeStore = IPlaygroundThemeStore()

  package init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  package var body: some View {
    let theme = themeStore.selectedTheme

    HomeView(store: store.scope(state: \.home, action: \.home))
      .environment(themeStore)
      .environment(\.iPlaygroundTheme, theme)
      .tint(theme.tint)
  }
}

#Preview {
  AppView(store: .init(initialState: .init(), reducer: { AppFeature() }))
}
