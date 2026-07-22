import Foundation

public struct ScheduledSession: Equatable, Hashable, Sendable {
  public let session: Session
  public let isWorkshop: Bool

  public init(session: Session, isWorkshop: Bool) {
    self.session = session
    self.isWorkshop = isWorkshop
  }

  public static func merged(sessions: [Session], workshops: [Session]) -> [Self] {
    let scheduledSessions =
      sessions.map { Self(session: $0, isWorkshop: false) }
      + workshops.map { Self(session: $0, isWorkshop: true) }

    return scheduledSessions.enumerated()
      .sorted { lhs, rhs in
        let lhsStart = lhs.element.startMinuteOfDay ?? .max
        let rhsStart = rhs.element.startMinuteOfDay ?? .max
        return lhsStart == rhsStart ? lhs.offset < rhs.offset : lhsStart < rhsStart
      }
      .map(\.element)
  }

  private var startMinuteOfDay: Int? {
    let startTime = session.time.trimmingCharacters(in: .whitespaces).prefix(5)
    let components = startTime.split(separator: ":")

    guard components.count == 2,
      let hour = Int(components[0]),
      let minute = Int(components[1]),
      (0...23).contains(hour),
      (0...59).contains(minute)
    else {
      return nil
    }

    return hour * 60 + minute
  }
}
