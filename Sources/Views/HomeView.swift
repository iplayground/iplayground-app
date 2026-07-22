import ComposableArchitecture
import Features
import Models
import SwiftUI

enum AppNavigationTitle: String {
  case activity = "活動"
  case scheduleAndWorkshops = "議程與工作坊"

  var localizedResource: LocalizedStringResource {
    switch self {
    case .activity:
      return LocalizedStringResource("活動", bundle: .module)
    case .scheduleAndWorkshops:
      return LocalizedStringResource("議程與工作坊", bundle: .module)
    }
  }
}

enum HomeTabPresentation {
  static let activitySymbol = "flag.pattern.checkered"
}

struct HomeView: View {
  let store: StoreOf<HomeFeature>

  init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  var body: some View {
    TabView {
      // Tab 1: Today
      TodayView(
        store: store.scope(state: \.today, action: \.today)
      )
      .tabItem { Label(String(localized: "議程", bundle: .module), systemImage: "calendar") }

      // Tab 2: Live captions
      LiveCaptionView(
        store: store.scope(state: \.liveCaption, action: \.liveCaption)
      )
      .tabItem { Label(String(localized: "字幕", bundle: .module), systemImage: "captions.bubble") }

      // Tab 3: Sponsors, Speakers, & Staff
      CommunityView(
        store: store.scope(state: \.community, action: \.community)
      )
      .tabItem { Label(String(localized: "社群", bundle: .module), systemImage: "person.3") }

      // Tab 4: Activity
      MyView(store: store.scope(state: \.my, action: \.my))
        .tabItem {
          Label {
            Text(AppNavigationTitle.activity.localizedResource)
          } icon: {
            Image(systemName: HomeTabPresentation.activitySymbol)
          }
        }

      // Tab 5: About
      AboutView(
        store: store.scope(state: \.about, action: \.about)
      )
      .tabItem { Label(String(localized: "關於", bundle: .module), systemImage: "info.circle") }
    }
    .task {
      await store.send(.task).finish()
    }
  }
}

#Preview("活動前") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = IPlaygroundEvent.date(month: 7, day: 24, hour: 9)
      return date
    }()
  }
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature() }
    )
  )
}

#Preview("活動中 - Day 1") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = IPlaygroundEvent.date(month: 7, day: 25, hour: 9, minute: 35)
      return date
    }()
  }
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature() }
    )
  )
}

#Preview("活動中 - Day 2") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = IPlaygroundEvent.date(month: 7, day: 26, hour: 17, minute: 10)
      return date
    }()
  }
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature() }
    )
  )
}

#Preview("活動結束後") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = IPlaygroundEvent.date(month: 7, day: 26, hour: 18)
      return date
    }()
  }
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature() }
    )
  )
}
