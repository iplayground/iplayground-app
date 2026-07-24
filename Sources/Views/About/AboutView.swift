import ComposableArchitecture
import Features
import MapKit
import Models
import SwiftUI

// Coordinate and address are hard-coded for the current event.

let coordinate = CLLocationCoordinate2D(
  latitude: 25.030146,
  longitude: 121.527629
)

@MainActor
let initialMapPosition: MapCameraPosition = .region(
  .init(
    center: coordinate,
    latitudinalMeters: 200,
    longitudinalMeters: 200
  )
)

@ViewAction(for: AboutFeature.self)
package struct AboutView: View {
  @Bindable package var store: StoreOf<AboutFeature>
  @State private var lookAroundScene: MKLookAroundScene?
  @Environment(\.iPlaygroundTheme) private var theme
  @Environment(IPlaygroundThemeStore.self) private var themeStore

  package init(store: StoreOf<AboutFeature>) {
    self.store = store
  }

  package var body: some View {
    NavigationStack {
      List {
        appIconSection
        mapSection
        importantLinksSection
        socialMediaSection
        appInfoSection
      }
      .navigationTitle(String(localized: "關於", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .task {
        send(.task)
      }
      .task {
        await requestLookAround()
      }
    }
  }

  @ViewBuilder
  private var appIconSection: some View {
    Section {
    } header: {
      HStack {
        Spacer()
        VStack(alignment: .center) {
          appIcon
            .resizable()
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 16))
          aboutLogo
        }
        Spacer()
      }
      .textCase(.none)
      .padding(.top)
      .padding(.bottom, -13)
    }
  }

  private var appIcon: Image {
    switch theme {
    case .y2026:
      return Image("iPlayground-2026", bundle: .module)
    case .y2025:
      return Image("iPlayground-2025", bundle: .module)
    }
  }

  @ViewBuilder
  private var aboutLogo: some View {
    switch theme {
    case .y2026:
      IPlaygroundWordmark()
    case .y2025:
      Text(verbatim: "iPlayground \(IPlaygroundEvent.yearString)")
        .font(.title)
        .monospaced()
    }
  }

  private let appleMapsLink = SwiftUI.Link(
    destination: URL(
      string:
        "https://maps.apple.com/place?coordinate=25.030146,121.527629&place-id=IC4414FF248A5DFE5"
    )!,
    label: {
      Label(String(localized: "打開 Apple 地圖", bundle: .module), systemImage: "map")
    }
  )

  private let googleMapsLink = SwiftUI.Link(
    destination: URL(string: "https://maps.app.goo.gl/un36yK3ptkxnUiTE6")!,
    label: {
      Label(String(localized: "打開 Google 地圖", bundle: .module), systemImage: "map")
    }
  )

  @ViewBuilder
  private var mapSection: some View {
    Section(String(localized: "場地", bundle: .module)) {
      HStack {
        Menu(
          content: {
            appleMapsLink
            googleMapsLink
          },
          label: {
            Map(initialPosition: initialMapPosition) {
              Annotation(String(localized: "政大公企中心", bundle: .module), coordinate: coordinate) {
                Image(systemName: "mappin.and.ellipse")
              }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 8))
          }
        )

        LookAroundPreview(
          scene: $lookAroundScene,
          allowsNavigation: true,
          showsRoadLabels: true
        )
        .aspectRatio(1, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 8))
      }

      Menu(
        content: {
          appleMapsLink
          googleMapsLink
        },
        label: {
          VStack {
            Label(
              title: {
                Text("政大公企中心", bundle: .module)
                  .multilineTextAlignment(.leading)
                Text("台北市大安區金華街 187 號", bundle: .module)
                  .multilineTextAlignment(.leading)
              },
              icon: {
                Image(systemName: "mappin.and.ellipse")
              }
            )
          }
          .contentShape(Rectangle())
        }
      )
    }
  }

  private func requestLookAround() async {
    Task.detached {
      let request = MKLookAroundSceneRequest(coordinate: coordinate)
      guard let scene = try? await request.scene else {
        return
      }
      Task { @MainActor in
        self.lookAroundScene = scene
      }
    }
  }

  @ViewBuilder
  private var importantLinksSection: some View {
    Section(String(localized: "重要連結", bundle: .module)) {
      ForEach(importantLinks) { link in
        urlMenuButton(link: link)
      }
    }
  }

  @ViewBuilder
  private var socialMediaSection: some View {
    if !socialMediaLinks.isEmpty {
      Section(String(localized: "社群媒體", bundle: .module)) {
        ForEach(socialMediaLinks) { link in
          urlMenuButton(link: link)
        }
      }
    }
  }

  @ViewBuilder
  private var appInfoSection: some View {
    Section(String(localized: "App 資訊", bundle: .module)) {
      HStack {
        Label(String(localized: "主題", bundle: .module), systemImage: "paintpalette")
        Spacer()
        Picker("", selection: selectedTheme) {
          ForEach(IPlaygroundTheme.allCases) { theme in
            Text(verbatim: theme.displayName)
              .tag(theme)
          }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(width: 150)
      }

      ForEach(appInfoLinks) { link in
        urlMenuButton(link: link)
      }

      // Link to Settings
      if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        let settingsLink = Models.Link(
          id: "licensePlist",
          title: String(localized: "Open Source Licenses", bundle: .module),
          url: settingsURL,
          icon: "list.bullet.rectangle",
          type: .appInfo
        )
        urlMenuButton(link: settingsLink)
      }

      if !store.appVersion.isEmpty {
        HStack {
          Label(String(localized: "版本資訊", bundle: .module), systemImage: "info.circle")
          Spacer()
          Text(verbatim: "\(store.appVersion) (\(store.buildNumber))")
            .foregroundColor(.secondary)
        }
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
          Label(link.localizedTitle, systemImage: iconName)
        } else {
          Text(link.localizedTitle)
        }
        Spacer()
        Image(systemName: "arrow.up.right.square")
          .foregroundStyle(theme.tint)
      }
    }
  }

  private var importantLinks: [Models.Link] {
    store.links.filter { link in
      link.type == .primary
    }
  }

  private var socialMediaLinks: [Models.Link] {
    store.links.filter { link in
      link.type == .social
    }
  }

  private var appInfoLinks: [Models.Link] {
    store.links.filter { link in
      link.type == .appInfo
    }
  }

  private var selectedTheme: Binding<IPlaygroundTheme> {
    Binding {
      themeStore.selectedTheme
    } set: { newValue in
      themeStore.selectTheme(newValue)
    }
  }
}

// Link title localized by ID

extension Models.Link {
  var localizedTitle: String {
    switch id {
    case "website":
      return String(localized: "Website", bundle: .module)
    case "coc":
      return String(localized: "Code of Conduct", bundle: .module)
    case "hackmd":
      return String(localized: "HackMD", bundle: .module)
    case "newsletter":
      return String(localized: "Newsletter", bundle: .module)
    case "youtube":
      return "YouTube"
    case "discord":
      return "Discord"
    case "twitter":
      return "Twitter (X)"
    case "threads":
      return "Threads"
    case "mastodon":
      return "Mastodon"
    case "facebook":
      return "Facebook"
    case "app-source":
      return "iplayground-app"
    case "session-data-source":
      return "SessionData"
    case "app-store":
      return "App Store"
    case "privacy-policy":
      return String(localized: "Privacy Policy", bundle: .module)
    case "kktix":
      return String(localized: "KKTIX", bundle: .module)
    case "notice":
      return String(localized: "Notice", bundle: .module)
    case "lightning-talk":
      return String(localized: "Lightning Talk", bundle: .module)
    default:
      return title
    }
  }
}

#Preview {
  NavigationStack {
    AboutView(
      store: .init(
        initialState: .init(),
        reducer: { AboutFeature() }
      )
    )
    .environment(IPlaygroundThemeStore())
  }
}
