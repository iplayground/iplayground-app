import ComposableArchitecture
import Dependencies
import Features
import Models
import SwiftUI

@ViewAction(for: TodayFeature.self)
struct TodayView: View {
  @Bindable var store: StoreOf<TodayFeature>
  @State private var nowSectionID: Int = 0
  @Environment(\.iPlaygroundTheme) private var theme

  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path),
      root: { rootView },
      destination: { store in
        switch store.case {
        case let .speaker(store):
          SpeakerView(store: store)
        }
      }
    )
  }

  @ViewBuilder
  private var rootView: some View {
    VStack(spacing: 0) {
      dayPicker
      ScrollViewReader { proxy in
        List {
          sessionList
        }
        .listStyle(.inset)
        .contentMargins(.vertical, -4, for: .scrollIndicators)
        .searchable(text: $store.searchText)
        .safeAreaInset(edge: .bottom) {
          VStack {
            Button(
              action: {
                if let currentSession = store.currentSession {
                  // XXX: Change segmented control first
                  // then scroll to current session cell
                  send(.tapNowSection)

                  Task { @MainActor in
                    withAnimation {
                      proxy.scrollTo(currentSession.id)
                    }
                  }
                }
              },
              label: {
                nowSection
                  .id(nowSectionID)
              }
            )
            .buttonStyle(.plain)
            .padding()
            .background(theme.widgetBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom)
          }
        }
      }
    }
    .navigationTitle(String(localized: "議程與活動", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .task {
      send(.task)
    }
    .task {
      Task {
        while Task.isCancelled == false {
          try await Task.sleep(for: .seconds(15))
          nowSectionID += 1
        }
      }
    }
  }

  @ViewBuilder
  private var nowSection: some View {
    if let startDate = store.day1Sessions.first?.dateInterval?.start,
      let endDate = store.day2Sessions.last?.dateInterval?.end
    {
      @Dependency(\.date.now) var now

      // 情況 1：活動開始之前
      if now < startDate {
        HStack {
          Text(
            """
            \(Text(verbatim: "iPlayground").foregroundStyle(theme.primary)) \(Text(verbatim: IPlaygroundEvent.yearString).foregroundStyle(theme.secondary))
            \(Text(startDate, style: .relative).foregroundStyle(theme.tertiary))
            """
          )
          .font(.headline)
          Spacer()
        }
      } else if now > endDate {
        // 情況 2：活動已結束
        HStack {
          Text(
            """
            \(Text(verbatim: "iPlayground").foregroundStyle(theme.primary)) \(Text(verbatim: IPlaygroundEvent.yearString).foregroundStyle(theme.secondary))
            \(Text("活動已結束，感謝您的參與！", bundle: .module).foregroundStyle(theme.tertiary))
            """
          )
          .font(.headline)
          .multilineTextAlignment(.leading)
          Spacer()
        }
      } else {
        // 情況 3：活動進行中
        HStack {
          VStack(alignment: .leading) {
            if let currentSession = store.currentSession {
              let duration = Duration.seconds(
                currentSession.dateInterval?.end.timeIntervalSince(now) ?? 0)
              Text(
                """
                👉 \(currentSession.title)\(currentSession.speaker.isEmpty ? "" : " - \(currentSession.speaker)")（剩餘：\(Text(duration.formatted(.units(allowed: [.hours, .minutes], width: .narrow))))）
                """,
                bundle: .module
              )
              .font(.headline)
              .foregroundStyle(theme.primary)
            }

            if let nextSession = store.nextSession {
              Text(
                "\(Text(nextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextSession.title)\(nextSession.speaker.isEmpty ? "" : " - \(nextSession.speaker)")",
                bundle: .module
              )
              .font(.subheadline)
              .foregroundStyle(theme.tertiary)
            }

            if let nextNextSession = store.nextNextSession {
              Text(
                "\(Text(nextNextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextNextSession.title)\(nextNextSession.speaker.isEmpty ? "" : " - \(nextNextSession.speaker)")",
                bundle: .module
              )
              .font(.subheadline)
              .foregroundStyle(theme.secondary)
            }
          }
          Spacer()
        }
      }
    }
  }

  @ViewBuilder
  private var dayPicker: some View {
    Picker("", selection: $store.selectedDay) {
      ForEach(TodayFeature.State.Day.allCases) { day in
        (Text(day.localizedStringKey, bundle: .module)
          + Text(verbatim: " - ")
          + Text(day.startOfDay, format: Date.FormatStyle().month(.abbreviated).day()))
          .tag(day)
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
    .padding(.bottom, 8)
  }

  @ViewBuilder
  private var sessionList: some View {
    let currentSessionID = store.currentSession?.id

    ForEach(store.currentSessions) { session in
      if session.speakerID != nil {
        Button(
          action: {
            send(.tapSession(session))
          },
          label: {
            HStack {
              sessionCell(session)
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundStyle(theme.tint)
            }
          }
        )
        .listRowBackground(
          theme.widgetBackground.opacity(session.id == currentSessionID ? 1.0 : 0))
      } else {
        sessionCell(session)
          .listRowBackground(
            theme.widgetBackground.opacity(session.id == currentSessionID ? 1.0 : 0))
      }
    }
  }

  @ViewBuilder
  private func sessionCell(_ session: SessionWrapper) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 4) {
        if session.isWorkshop {
          Image(systemName: "hammer.fill")
            .foregroundStyle(theme.tint)
            .accessibilityLabel(Text("工作坊", bundle: .module))
        }

        Text(session.timeRange)
          .foregroundStyle(.secondary)

        if session.isRecording == false {
          Image(systemName: "video.slash.fill")
            .foregroundStyle(.secondary)
            .accessibilityLabel(Text("本場次無錄影", bundle: .module))
        }
      }
      .font(.footnote)

      Text(session.title)
        .font(.headline)
        .bold()

      if session.speaker.isEmpty == false {
        Text(session.speaker)
          .font(.subheadline)
      }

      if let tags = session.tags {
        Text(tags)
          .font(.footnote)
          .foregroundColor(.secondary)
      }

      if let description = session.description {
        Text(description)
          .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
    .id(session.id)
  }
}

extension TodayFeature.State.Day {
  var localizedStringKey: LocalizedStringKey {
    switch self {
    case .day1: return "第 1 天"
    case .day2: return "第 2 天"
    }
  }

  var startOfDay: Date {
    switch self {
    case .day1:
      return IPlaygroundEvent.day1Date
    case .day2:
      return IPlaygroundEvent.day2Date
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
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
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
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
    )
  )
}

#Preview("活動中 - Day 1 與 2 之間") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = IPlaygroundEvent.date(month: 7, day: 25, hour: 20, minute: 35)
      return date
    }()
  }
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
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
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
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
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
    )
  )
}
