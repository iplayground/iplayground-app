import ComposableArchitecture
import Features
import Models
import SwiftUI

@ViewAction(for: LiveCaptionFeature.self)
package struct LiveCaptionView: View {
  @Bindable package var store: StoreOf<LiveCaptionFeature>
  @Environment(\.iPlaygroundTheme) private var theme
  @State private var autoScroll = true
  private let messageBottomID = "_messageBottom"

  package init(store: StoreOf<LiveCaptionFeature>) {
    self.store = store
  }

  package var body: some View {
    NavigationStack {
      Group {
        if store.displayedCaptions.isEmpty {
          emptyView
        } else {
          messageList
        }
      }
      .navigationTitle(Text("即時字幕", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            send(.showLanguageSheet)
          } label: {
            Image(systemName: "globe")
          }
          .accessibilityLabel(Text("選擇語言", bundle: .module))
        }

        if store.connectionState == .reconnecting {
          ToolbarItem(placement: .topBarTrailing) {
            ProgressView()
              .accessibilityLabel(Text("重新連線中", bundle: .module))
          }
        }
      }
      .task {
        await send(.task).finish()
      }
      .sheet(isPresented: languageSheet) {
        LiveCaptionLanguageSheet(store: store)
          .presentationDetents([.medium, .large])
      }
      .alert(
        Text("字幕選項已更新", bundle: .module),
        isPresented: availabilityNotice
      ) {
        Button(String(localized: "好", bundle: .module)) {}
      } message: {
        Text("目前選擇不可用，已改用可用選項。", bundle: .module)
      }
    }
  }

  @ViewBuilder
  private var emptyView: some View {
    switch store.connectionState {
    case .idle, .connecting:
      ProgressView(String(localized: "讀取中…", bundle: .module))
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .reconnecting where store.errorMessage != nil:
      ContentUnavailableView {
        Label(
          String(localized: "暫時無法連線", bundle: .module),
          systemImage: "wifi.exclamationmark"
        )
      } description: {
        Text("請稍後再試，字幕會自動重新連線。", bundle: .module)
      } actions: {
        Button(String(localized: "重試", bundle: .module)) {
          send(.reconnect)
        }
        .buttonStyle(.bordered)
      }

    case .reconnecting:
      ProgressView(String(localized: "重新連線中", bundle: .module))
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .connected:
      ContentUnavailableView(
        emptyTitle,
        systemImage: "captions.bubble",
        description: Text(emptyDescription)
      )
    }
  }

  private var messageList: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(store.displayedCaptions) { caption in
            if let text = caption.text(for: store.selectedLanguage) {
              Text(text)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .padding()
            }
          }

          Color.clear
            .frame(height: 120)
            .id(messageBottomID)
        }
      }
      .onChange(of: store.displayedCaptions.last?.id) {
        scrollToBottomIfNeeded(proxy)
      }
      .overlay(alignment: .bottomTrailing) {
        Button {
          autoScroll.toggle()
          scrollToBottomIfNeeded(proxy)
        } label: {
          Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
            .font(.largeTitle)
            .padding()
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.tint)
        .accessibilityLabel(
          Text(
            autoScroll ? "停止自動捲動" : "開啟自動捲動",
            bundle: .module
          )
        )
      }
    }
  }

  private var languageSheet: Binding<Bool> {
    Binding {
      store.isShowingLanguageSheet
    } set: { isPresented in
      if !isPresented {
        send(.hideLanguageSheet)
      }
    }
  }

  private var availabilityNotice: Binding<Bool> {
    Binding {
      store.didFallbackSelection
    } set: { isPresented in
      if !isPresented {
        send(.dismissAvailabilityNotice)
      }
    }
  }

  private var emptyTitle: String {
    if store.sessionStatus == .started {
      return String(localized: "等待字幕", bundle: .module)
    } else {
      return String(localized: "還沒有字幕", bundle: .module)
    }
  }

  private var emptyDescription: String {
    if store.sessionStatus == .started {
      return String(localized: "收到字幕後會顯示在這裡。", bundle: .module)
    } else {
      return String(localized: "當議程開始時，字幕將顯示在這裡。", bundle: .module)
    }
  }

  private func scrollToBottomIfNeeded(_ proxy: ScrollViewProxy) {
    guard autoScroll else { return }
    withAnimation(.spring) {
      proxy.scrollTo(messageBottomID, anchor: .bottom)
    }
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
