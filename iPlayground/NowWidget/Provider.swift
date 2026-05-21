//
//  NowWidget.swift
//  NowWidget
//
//  Created by ethanhuang on 2025/8/28.
//

import Dependencies
import DependencyClients
import Models
import SessionData
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> NowEntry {
    @Dependency(\.date.now) var now
    let entry = NowEntry(date: now, phase: .afterEvent)
    return entry
  }

  func getSnapshot(in context: Context, completion: @escaping (NowEntry) -> Void) {
    @Dependency(\.date.now) var now
    let entry = NowEntry(date: now, phase: .afterEvent)
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<NowEntry>) -> Void) {
    Task {
      let result: Timeline<NowEntry>

      defer {
        completion(result)
      }

      @Dependency(\.iPlaygroundDataClient) var client
      @Dependency(\.date.now) var now

      do {
        // Fetch sessions for both days
        let (day1Sessions, day2Sessions) = try await Self.fetchSessions()
        let day1Date = IPlaygroundEvent.day1Date
        let day1Wrappers = Self.convertSessions(day1Sessions, date: day1Date)
        let day2Date = IPlaygroundEvent.day2Date
        let day2Wrappers = Self.convertSessions(day2Sessions, date: day2Date)
        let allSessions = day1Wrappers + day2Wrappers

        var entries: [NowEntry] = []

        if let eventStartDate = allSessions.first?.dateInterval?.start,
          now < eventStartDate
        {
          let before = NowEntry(
            date: now, phase: .beforeEvent(eventStartDate: eventStartDate))
          entries.append(before)
        }

        entries.append(contentsOf: Self.convertSessionWrappers(allSessions))

        if let eventEndDate = allSessions.last?.dateInterval?.end {
          let after = NowEntry(date: eventEndDate, phase: .afterEvent)
          entries.append(after)
        }

        result = Timeline(entries: entries, policy: .atEnd)
      } catch {
        // Fallback entry on error
        let fallbackStartDate = IPlaygroundEvent.day1Date.addingTimeInterval(
          9 * 3600)
        let entry = NowEntry(date: now, phase: .beforeEvent(eventStartDate: fallbackStartDate))
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        result = timeline
      }
    }
  }

  static func fetchSessions() async throws -> ([Session], [Session]) {
    @Dependency(\.iPlaygroundDataClient) var client
    let day1Sessions = try await client.fetchSchedules(1, .cacheFirst)
    let day2Sessions = try await client.fetchSchedules(2, .cacheFirst)
    return (day1Sessions, day2Sessions)
  }

  static func convertSessions(_ sessions: [Session], date: Date) -> [SessionWrapper] {
    sessions.map { SessionWrapper(date: date, session: $0) }
  }

  static func convertSessionWrappers(_ allSessions: [SessionWrapper]) -> [NowEntry] {
    @Dependency(\.date.now) var now

    var entries: [NowEntry] = []

    // Generate entries for all session start and end times
    for session in allSessions {
      guard let dateInterval = session.dateInterval else { continue }

      // Entry at session start
      let currentSession = session
      let nextSession = findNextSession(from: allSessions, after: dateInterval.start)
      let nextNextSession = findNextNextSession(from: allSessions, after: nextSession)

      entries.append(
        NowEntry(
          date: dateInterval.start,
          phase: .duringEvent(
            currentSession: currentSession,
            nextSession: nextSession,
            nextNextSession: nextNextSession
          )
        ))

      if let nextStart = nextSession?.dateInterval?.start,
        nextStart != dateInterval.end
      {
        entries.append(
          NowEntry(
            date: dateInterval.end,
            phase: .duringEvent(
              currentSession: nil,
              nextSession: nextSession,
              nextNextSession: nextNextSession
            )
          ))
      }
    }

    // Filter entries to only include future ones
    let finalEntries =
      entries
      .sorted(using: KeyPathComparator(\.date))
      .filter { $0.date >= now }
    return finalEntries
  }
}

private func findCurrentSession(from sessions: [SessionWrapper], at date: Date) -> SessionWrapper? {
  return sessions.first { $0.dateInterval?.contains(date) ?? false }
}

private func findNextSession(from sessions: [SessionWrapper], after date: Date) -> SessionWrapper? {
  return sessions.first { ($0.dateInterval?.start ?? .distantFuture) > date }
}

private func findNextNextSession(
  from sessions: [SessionWrapper], after nextSession: SessionWrapper?
) -> SessionWrapper? {
  guard let date = nextSession?.dateInterval?.end else {
    return nil
  }
  return sessions.first { $0.dateInterval?.start ?? .distantFuture >= date }
}
