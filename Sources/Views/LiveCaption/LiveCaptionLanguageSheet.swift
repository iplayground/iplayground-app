import ComposableArchitecture
import Features
import Models
import SwiftUI

@ViewAction(for: LiveCaptionFeature.self)
package struct LiveCaptionLanguageSheet: View {
  @Bindable package var store: StoreOf<LiveCaptionFeature>
  @Environment(\.iPlaygroundTheme) private var theme

  package init(store: StoreOf<LiveCaptionFeature>) {
    self.store = store
  }

  package var body: some View {
    NavigationStack {
      List {
        Section {
          Stepper(value: trackNumber, in: 1...Int.max) {
            LabeledContent(
              String(localized: "字幕軌道", bundle: .module),
              value: String(store.trackNumber)
            )
          }
        }

        if modeOptions.count > 1 {
          Section(String(localized: "字幕模式", bundle: .module)) {
            Picker(
              String(localized: "字幕模式", bundle: .module),
              selection: captionMode
            ) {
              ForEach(modeOptions) { mode in
                Text(mode.localizedDisplayName)
                  .tag(mode)
              }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
          }
        }

        Section {
          ForEach(languageOptions) { language in
            Button {
              send(.changeLanguage(language))
            } label: {
              HStack {
                Text(language.localizedDisplayName)
                  .foregroundStyle(.primary)

                Spacer()

                if language == store.selectedLanguage {
                  Image(systemName: "checkmark")
                    .foregroundStyle(theme.tint)
                }
              }
              .padding(.vertical, 8)
              .contentShape(.rect)
            }
            .buttonStyle(.plain)
          }
        }
      }
      .listStyle(.plain)
      .navigationTitle(String(localized: "選擇語言", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(String(localized: "取消", bundle: .module)) {
            send(.hideLanguageSheet)
          }
        }
      }
    }
  }

  private var captionMode: Binding<LiveCaptionMode> {
    Binding {
      store.selectedMode
    } set: { mode in
      send(.changeCaptionMode(mode))
    }
  }

  private var trackNumber: Binding<Int> {
    Binding {
      store.trackNumber
    } set: { trackNumber in
      send(.changeTrackNumber(trackNumber))
    }
  }

  private var modeOptions: [LiveCaptionMode] {
    store.availableModes.isEmpty ? LiveCaptionMode.allCases : store.availableModes
  }

  private var languageOptions: [LiveCaptionLanguage] {
    store.availableLanguages.isEmpty ? LiveCaptionLanguage.allCases : store.availableLanguages
  }
}

#Preview {
  LiveCaptionLanguageSheet(
    store: Store(
      initialState: LiveCaptionFeature.State(),
      reducer: { LiveCaptionFeature() }
    )
  )
}
