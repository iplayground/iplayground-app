import Testing

@testable import Models

@Suite("ScheduledSession Tests")
struct ScheduledSessionTests {
  @Test("Merge sessions and workshops chronologically")
  func mergeChronologically() {
    let sessions = [
      makeSession(time: "09:00 - 09:30", title: "Opening"),
      makeSession(time: "13:00 - 13:20", title: "Afternoon Session"),
    ]
    let workshops = [
      makeSession(time: "10:30 - 12:00", title: "Morning Workshop"),
      makeSession(time: "15:15 - 16:45", title: "Afternoon Workshop"),
    ]

    let result = ScheduledSession.merged(sessions: sessions, workshops: workshops)

    #expect(
      result.map(\.session.title) == [
        "Opening",
        "Morning Workshop",
        "Afternoon Session",
        "Afternoon Workshop",
      ])
    #expect(result.map(\.isWorkshop) == [false, true, false, true])
  }

  @Test("Preserve source order when start times match")
  func preserveSourceOrderForMatchingTimes() {
    let sessions = [
      makeSession(time: "13:00 - 13:20", title: "Session 1"),
      makeSession(time: "13:00 - 13:20", title: "Session 2"),
    ]
    let workshops = [
      makeSession(time: "13:00 - 14:30", title: "Workshop")
    ]

    let result = ScheduledSession.merged(sessions: sessions, workshops: workshops)

    #expect(result.map(\.session.title) == ["Session 1", "Session 2", "Workshop"])
  }

  private func makeSession(time: String, title: String) -> Session {
    Session(
      time: time,
      title: title,
      tags: [],
      speaker: "",
      speakerID: nil,
      description: ""
    )
  }
}
