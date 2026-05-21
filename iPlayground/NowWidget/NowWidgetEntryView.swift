//
//  NowWidgetEntryView.swift
//  iPlayground
//
//  Created by ethanhuang on 2025/8/28.
//

import Models
import SwiftUI
import WidgetKit

struct NowWidgetEntryView: View {
  var entry: Provider.Entry

  @Environment(\.widgetFamily) var widgetFamily
  @Environment(\.iPlaygroundTheme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      switch entry.phase {
      case let .beforeEvent(eventStartDate):
        beforeEventView(eventStartDate: eventStartDate)
      case let .duringEvent(currentSession, nextSession, nextNextSession):
        duringEventView(
          currentSession: currentSession,
          nextSession: nextSession,
          nextNextSession: nextNextSession
        )
      case .afterEvent:
        afterEventView
      }
    }
  }

  @ViewBuilder
  private func beforeEventView(eventStartDate: Date) -> some View {
    Text(
      """
      \(Text(verbatim: "iPlayground").foregroundStyle(theme.primary)) \(Text(verbatim: IPlaygroundEvent.yearString).foregroundStyle(theme.secondary))
      \(Text(eventStartDate, style: .relative).foregroundStyle(theme.tertiary))
      """
    )
    .font(.headline)
    .multilineTextAlignment(.center)
  }

  @ViewBuilder
  private func duringEventView(
    currentSession: SessionWrapper?,
    nextSession: SessionWrapper?,
    nextNextSession: SessionWrapper?
  ) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        if let currentSession = currentSession {
          Text(
            """
            👉 \(currentSession.title)\(currentSession.speaker.isEmpty ? "" : " - \(currentSession.speaker)")
            """
          )
          .font(.headline)
          .foregroundStyle(theme.primary)
        }

        if let nextSession = nextSession {
          Text(
            "\(Text(nextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextSession.title)\(nextSession.speaker.isEmpty ? "" : " - \(nextSession.speaker)")"
          )
          .font(.subheadline)
          .foregroundStyle(theme.tertiary)
        }

        if widgetFamily != .systemSmall {
          if let nextNextSession = nextNextSession {
            Text(
              "\(Text(nextNextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextNextSession.title)\(nextNextSession.speaker.isEmpty ? "" : " - \(nextNextSession.speaker)")"
            )
            .font(.subheadline)
            .foregroundStyle(theme.secondary)
          }
        }
      }
      Spacer()
    }
  }

  @ViewBuilder
  private var afterEventView: some View {
    Text(
      """
      \(Text(verbatim: "iPlayground").foregroundStyle(theme.primary)) \(Text(verbatim: IPlaygroundEvent.yearString).foregroundStyle(theme.secondary))
      \(Text("活動已結束，感謝您的參與！").foregroundStyle(theme.tertiary))
      """
    )
    .font(.headline)
    .multilineTextAlignment(.center)
  }
}
