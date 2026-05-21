import ComposableArchitecture
import Features
import SwiftUI

@ViewAction(for: LiveTranslationFeature.self)
package struct LiveTranslationView: View {
  @Bindable package var store: StoreOf<LiveTranslationFeature>
  @State private var autoScroll = true
  @Environment(\.iPlaygroundTheme) private var theme
  private let messageBottomID = "_messageBottom"

  package init(store: StoreOf<LiveTranslationFeature>) {
    self.store = store
  }

  package var body: some View {
    NavigationStack {
      VStack {
        if store.isLoading {
          loadingView
        } else if let errorMessage = store.errorMessage {
          errorView(errorMessage: errorMessage)
        } else {
          if store.chatList.isEmpty {
            emptyList
          } else {
            messageList
          }
        }
      }
      .navigationTitle(Text("即時翻譯", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          switchLanguageButton
        }

        ToolbarItem(placement: .topBarTrailing) {
          webpageButton
        }
      }
      .task {
        send(.task)
        send(.connectStream)
      }
      .sheet(isPresented: $store.isShowingLanguageSheet) {
        SelectLanguageSheet(store: store)
          .presentationDetents([.medium, .large])
      }
    }
  }

  @ViewBuilder
  private var switchLanguageButton: some View {
    Button(action: { send(.showLanguageSheet) }) {
      Image(systemName: "globe")
    }
  }

  @ViewBuilder
  private var webpageButton: some View {
    Button(
      action: { send(.tapWebpageButton) },
      label: {
        Image(systemName: "arrow.up.right.square")
      }
    )
  }

  @ViewBuilder
  private var loadingView: some View {
    ProgressView(String(localized: "讀取中…", bundle: .module))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder
  private func errorView(errorMessage: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundColor(.orange)

      Text("發生錯誤", bundle: .module)
        .font(.headline)
        .foregroundColor(.primary)

      Text(errorMessage)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button(String(localized: "重試", bundle: .module)) {
        send(.task)
      }
      .buttonStyle(.bordered)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // XXX: SwiftUI doesn't correctly support RTL languages, so we need to manually set the layout direction.
  private var isRTL: Bool {
    let rtlLanguages = [
      "ar",  // Arabic
      "he",  // Hebrew
      "fa",  // Persian/Farsi
      "ur",  // Urdu
      "yi",  // Yiddish
      "ji",  // Yiddish (old code)
      "iw",  // Hebrew (old code)
    ]
    return rtlLanguages.contains(store.selectedLangCode)
  }

  @ViewBuilder
  private var messageList: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack {
          ForEach(store.chatList) { item in
            Text(item.translatedText ?? item.text)
              .frame(maxWidth: .infinity, alignment: .leading)
              .multilineTextAlignment(.leading)
              .padding()
          }
        }
        Text(verbatim: "\n\n\n\n\n\n")
          .id(messageBottomID)
      }
      .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
      .onChange(of: store.chatList) { oldValue, newValue in
        autoScrollToBottomIfNeeded(proxy: proxy)
      }
      .overlay(alignment: .bottom) {
        Button(
          action: {
            autoScroll.toggle()
            autoScrollToBottomIfNeeded(proxy: proxy)
          },
          label: {
            Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
              .imageScale(.large)
              .font(.largeTitle)
              .foregroundStyle(theme.tint)
              .padding()
          }
        )
      }
    }
  }

  private func autoScrollToBottomIfNeeded(proxy: ScrollViewProxy) {
    if autoScroll {
      withAnimation(.spring) {
        proxy.scrollTo(messageBottomID, anchor: .bottom)
      }
    }
  }

  @ViewBuilder
  private var emptyList: some View {
    ContentUnavailableView(
      String(localized: "還沒有訊息", bundle: .module),
      systemImage: "bubble.left.and.bubble.right",
      description: Text("當議程開始時，翻譯將顯示在這裡", bundle: .module)
    )
  }
}

#Preview {
  LiveTranslationView(
    store: Store(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )
  )
}

#Preview("No messages yet") {
  let _ = prepareDependencies {
    $0.liveTranslationClient.getLangList = { [] }
    $0.liveTranslationClient.chatConnection = { _ in .never }
  }

  LiveTranslationView(
    store: Store(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )
  )
}
