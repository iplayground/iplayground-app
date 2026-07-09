import ComposableArchitecture
import Features
import Models
import SwiftUI

@ViewAction(for: LiveCaptionFeature.self)
package struct LiveCaptionView: View {
  @Bindable package var store: StoreOf<LiveCaptionFeature>
  @Environment(\.iPlaygroundTheme) private var theme

  package init(store: StoreOf<LiveCaptionFeature>) {
    self.store = store
  }

  package var body: some View {
    NavigationStack {
      List {
        statusSection
        settingsSection
        captionsSection
      }
      .navigationTitle(String(localized: "即時字幕", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .task {
        send(.task)
      }
    }
  }

  @ViewBuilder
  private var statusSection: some View {
    Section {
      Label {
        VStack(alignment: .leading, spacing: 4) {
          Text(statusTitle)
          if let statusDetail {
            Text(statusDetail)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
      } icon: {
        Image(systemName: statusIcon)
          .foregroundStyle(statusColor)
      }

      if let errorMessage = store.errorMessage {
        Text(errorMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  @ViewBuilder
  private var settingsSection: some View {
    Section(String(localized: "字幕設定", bundle: .module)) {
      Stepper(value: trackNumber, in: 1...9) {
        LabeledContent(String(localized: "字幕軌道", bundle: .module)) {
          Text(verbatim: "\(store.trackNumber)")
        }
      }

      Picker(String(localized: "模式", bundle: .module), selection: captionMode) {
        ForEach(modeOptions) { mode in
          Text(mode.displayName)
            .tag(mode)
        }
      }

      Picker(String(localized: "語言", bundle: .module), selection: language) {
        ForEach(languageOptions) { language in
          Text(language.displayName)
            .tag(language)
        }
      }
    }
  }

  @ViewBuilder
  private var captionsSection: some View {
    Section(String(localized: "字幕", bundle: .module)) {
      let captions = store.displayedCaptions
      if captions.isEmpty {
        ContentUnavailableView(
          emptyTitle,
          systemImage: emptyIcon,
          description: Text(emptyDescription)
        )
        .frame(maxWidth: .infinity)
      } else {
        ForEach(captions) { caption in
          captionRow(caption)
        }
      }
    }
  }

  @ViewBuilder
  private func captionRow(_ caption: LiveCaptionItem) -> some View {
    if let text = caption.text(for: store.selectedLanguage) {
      VStack(alignment: .leading, spacing: 8) {
        Text(text)
          .font(.title3)
          .fontWeight(.medium)
          .textSelection(.enabled)

        HStack(spacing: 8) {
          Text("#\(caption.sequence)")
          Text(caption.captionMode.displayName)
          if let createdAt = caption.createdAt {
            Text(createdAt, style: .time)
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      .padding(.vertical, 4)
    }
  }

  private var trackNumber: Binding<Int> {
    Binding {
      store.trackNumber
    } set: { trackNumber in
      send(.changeTrackNumber(trackNumber))
    }
  }

  private var captionMode: Binding<LiveCaptionMode> {
    Binding {
      store.selectedMode
    } set: { mode in
      send(.changeCaptionMode(mode))
    }
  }

  private var language: Binding<LiveCaptionLanguage> {
    Binding {
      store.selectedLanguage
    } set: { language in
      send(.changeLanguage(language))
    }
  }

  private var modeOptions: [LiveCaptionMode] {
    store.availableModes.isEmpty ? LiveCaptionMode.allCases : store.availableModes
  }

  private var languageOptions: [LiveCaptionLanguage] {
    store.availableLanguages.isEmpty ? LiveCaptionLanguage.allCases : store.availableLanguages
  }

  private var statusTitle: String {
    switch store.connectionState {
    case .idle, .connecting:
      return String(localized: "連線中", bundle: .module)
    case .reconnecting:
      return String(localized: "重新連線中", bundle: .module)
    case .connected:
      switch store.portalStatus {
      case .offline:
        return String(localized: "Portal 尚未上線", bundle: .module)
      case .online:
        switch store.sessionStatus {
        case .started:
          return String(localized: "字幕 session 進行中", bundle: .module)
        case .stopped:
          return String(localized: "字幕 session 已停止", bundle: .module)
        case nil:
          return String(localized: "等待字幕 session", bundle: .module)
        }
      case nil:
        return String(localized: "等待 Portal 狀態", bundle: .module)
      }
    }
  }

  private var statusDetail: String? {
    if !store.availableModes.isEmpty || !store.availableLanguages.isEmpty {
      return String(
        localized:
          "可用：\(store.availableModes.map(\.displayName).joined(separator: "、")) / \(store.availableLanguages.map(\.displayName).joined(separator: "、"))",
        bundle: .module
      )
    }

    return String(localized: "尚未收到字幕可用性狀態", bundle: .module)
  }

  private var statusIcon: String {
    switch store.connectionState {
    case .idle, .connecting, .reconnecting:
      return "antenna.radiowaves.left.and.right"
    case .connected:
      if store.sessionStatus == .started {
        return "captions.bubble.fill"
      } else {
        return "captions.bubble"
      }
    }
  }

  private var statusColor: Color {
    if store.connectionState == .connected && store.sessionStatus == .started {
      return theme.tint
    } else {
      return .secondary
    }
  }

  private var emptyTitle: String {
    switch store.connectionState {
    case .idle, .connecting, .reconnecting:
      return String(localized: "正在連線", bundle: .module)
    case .connected:
      if store.sessionStatus == .started {
        return String(localized: "等待字幕", bundle: .module)
      } else {
        return String(localized: "尚無字幕", bundle: .module)
      }
    }
  }

  private var emptyDescription: String {
    switch store.portalStatus {
    case .offline:
      return String(localized: "Portal 上線後會自動更新。", bundle: .module)
    default:
      return String(localized: "收到字幕事件後會顯示在這裡。", bundle: .module)
    }
  }

  private var emptyIcon: String {
    "captions.bubble"
  }
}

#Preview {
  LiveCaptionView(
    store: Store(
      initialState: LiveCaptionFeature.State(),
      reducer: { LiveCaptionFeature() }
    )
  )
}
