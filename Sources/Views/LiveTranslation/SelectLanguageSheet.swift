import ComposableArchitecture
import DependencyClients
import Features
import Models
import SwiftUI

@ViewAction(for: LiveTranslationFeature.self)
package struct SelectLanguageSheet: View {
  @Bindable package var store: StoreOf<LiveTranslationFeature>
  @Environment(\.iPlaygroundTheme) private var theme

  package init(store: StoreOf<LiveTranslationFeature>) {
    self.store = store
  }

  package var body: some View {
    NavigationStack {
      List {
        ForEach(languagesWithTitles, id: \.langCode) { lang in
          Button(action: { send(.changeLanguage(lang.langCode)) }) {
            HStack {
              Text(lang.langTitle)

              Spacer()

              if lang.langCode == store.selectedLangCode {
                Image(systemName: "checkmark")
                  .foregroundStyle(theme.tint)
              }
            }
            .padding()
            .contentShape(.rect)
          }
          .buttonStyle(.plain)
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

  private var languagesWithTitles: [LanguageWithTitle] {
    return store.langList.map { item in
      // Use langSet translation if available, otherwise fall back to the language's own name
      let title = store.langSet?.langCodingKey(item.langCode) ?? item.name
      return LanguageWithTitle(langCode: item.langCode, langTitle: title)
    }
  }
}

private struct LanguageWithTitle: Equatable {
  let langCode: String
  let langTitle: String
}

#Preview {
  var state = LiveTranslationFeature.State()
  state.langList = [
    LanguageItem(id: "en", langCode: "en", name: "English"),
    LanguageItem(id: "zh", langCode: "zh", name: "中文"),
    LanguageItem(id: "ja", langCode: "ja", name: "日本語"),
  ]
  state.langSet = LangSet(data: ["en": "English", "zh": "中文", "ja": "日本語"])

  return SelectLanguageSheet(
    store: Store(
      initialState: state,
      reducer: { LiveTranslationFeature() }
    )
  )
}
