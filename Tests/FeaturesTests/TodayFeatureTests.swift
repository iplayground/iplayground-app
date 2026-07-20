import ComposableArchitecture
import Dependencies
import Foundation
import Models
import SessionData
import XCTest

@testable import Features

@MainActor
final class TodayFeatureTests: XCTestCase {

  func testTaskActionReturnsEffect() async {
    // Test that the task action returns a non-none effect
    // The concurrent execution details are tested in integration tests elsewhere
    let store = TestStore(initialState: TodayFeature.State()) {
      TodayFeature()
    } withDependencies: {
      $0.iPlaygroundDataClient.fetchAgenda = { day, _ in
        return []  // Return empty for simplicity
      }
      $0.date.now = createDate(year: 2025, month: 1, day: 15)
    }

    // Just verify the task starts without error
    await store.send(\.view.task)
    await store.skipReceivedActions(strict: false)
  }

  func testBindingDay1SessionsWithInitialLoad() async {
    // Set now to 3 PM (15:00) so it's definitely after the session end time (10:00)
    let today = createDate(year: 2025, month: 1, day: 15)
    let now = today.addingTimeInterval(15 * 60 * 60)  // 3 PM

    let day1Session = createMockSessionWrapper(
      timeRange: "08:00-10:00",
      title: "Day 1 Session",
      start: today.addingTimeInterval(8 * 60 * 60),  // 8 AM
      end: today.addingTimeInterval(10 * 60 * 60)  // 10 AM
    )

    let store = TestStore(initialState: TodayFeature.State()) {
      TodayFeature()
    } withDependencies: {
      $0.date.now = now
    }

    await store.send(.loadedDay1Sessions([day1Session])) {
      $0.$day1Sessions.withLock { $0 = [day1Session] }
      $0.selectedDay = .day2
      $0.initialLoaded = true
    }

    await store.send(.loadedDay1Sessions([day1Session]))
  }

  func testBindingDay1SessionsWithoutAutoSwitchToDay2() async {
    let sessionDate = createDate(year: 2025, month: 1, day: 15)

    let session = makeSession(
      time: "12:00-14:00",
      title: "Day 1 Session",
      tags: [],
      speaker: "Test Speaker",
      speakerID: 0,
      description: "Test description"
    )

    let day1Session = SessionWrapper(date: sessionDate, session: session)

    let store = TestStore(initialState: TodayFeature.State()) {
      TodayFeature()
    } withDependencies: {
      $0.date.now = sessionDate.addingTimeInterval(10 * 60 * 60)
    }

    store.assert {
      $0.selectedDay = .day1
    }

    await store.send(.loadedDay1Sessions([day1Session])) {
      $0.$day1Sessions.withLock { $0 = [day1Session] }
      $0.initialLoaded = true
    }
  }

  func testBindingDay1SessionsAlreadyLoaded() async {
    let day1Session = createMockSessionWrapper(timeRange: "10:00-11:00", title: "Day 1 Session")

    var initialState = TodayFeature.State()
    initialState.initialLoaded = true

    let store = TestStore(initialState: initialState) {
      TodayFeature()
    }

    await store.send(.loadedDay1Sessions([day1Session])) {
      $0.$day1Sessions.withLock { $0 = [day1Session] }
    }
  }

  func testBindingOtherProperties() async {
    let store = TestStore(initialState: TodayFeature.State()) {
      TodayFeature()
    }

    await store.send(\.binding.selectedDay, .day2) {
      $0.selectedDay = .day2
    }
  }

  func testTapNowSectionWithCurrentSessionOnDay1() async {
    let sessionDate = createDate(year: 2025, month: 1, day: 15)
    let now = sessionDate.addingTimeInterval(10 * 60 * 60 + 30 * 60)  // 10:30 AM

    let session = makeSession(
      time: "10:00-11:00",
      title: "Current Session",
      tags: [],
      speaker: "Test Speaker",
      speakerID: 0,
      description: "Test description"
    )

    let currentSession = SessionWrapper(date: sessionDate, session: session)

    var initialState = TodayFeature.State()
    initialState.$day1Sessions.withLock { $0 = [currentSession] }
    initialState.selectedDay = .day2

    let store = TestStore(initialState: initialState) {
      TodayFeature()
    } withDependencies: {
      $0.date.now = now
    }

    await store.send(\.view.tapNowSection) {
      $0.selectedDay = .day1
    }
  }

  func testTapNowSectionWithCurrentSessionOnDay2() async {
    let sessionDate = createDate(year: 2025, month: 1, day: 15)
    let now = sessionDate.addingTimeInterval(10 * 60 * 60 + 30 * 60)  // 10:30 AM

    let session = makeSession(
      time: "10:00-11:00",
      title: "Current Session",
      tags: [],
      speaker: "Test Speaker",
      speakerID: 0,
      description: "Test description"
    )

    let currentSession = SessionWrapper(date: sessionDate, session: session)

    var initialState = TodayFeature.State()
    initialState.$day2Sessions.withLock { $0 = [currentSession] }
    initialState.selectedDay = .day1

    let store = TestStore(initialState: initialState) {
      TodayFeature()
    } withDependencies: {
      $0.date.now = now
    }

    await store.send(\.view.tapNowSection) {
      $0.selectedDay = .day2
    }
  }

  func testTapNowSectionWithNoCurrentSession() async {
    let store = TestStore(initialState: TodayFeature.State()) {
      TodayFeature()
    }

    await store.send(\.view.tapNowSection)
  }

  // MARK: - Helper Methods

  private func createMockSessionWrapper(
    timeRange: String,
    title: String,
    speaker: String = "Test Speaker",
    start: Date? = nil,
    end: Date? = nil
  ) -> SessionWrapper {
    if let start = start, end != nil {
      let calendar = Calendar(identifier: .gregorian)
      let date = calendar.startOfDay(for: start)
      let session = makeSession(
        time: timeRange,
        title: title,
        tags: [],
        speaker: speaker,
        speakerID: 0,
        description: "Test description"
      )
      return SessionWrapper(date: date, session: session)
    } else {
      return SessionWrapper(
        timeRange: timeRange,
        title: title,
        speaker: speaker,
        speakerID: 0,
        tags: nil,
        description: "Test description",
        hackMDURL: nil
      )
    }
  }

  private func createDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

    let components = DateComponents(year: year, month: month, day: day)
    return calendar.date(from: components)!
  }
}
