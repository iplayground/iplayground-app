import Foundation
@_exported import SessionData

public struct SessionWrapper: Identifiable, Equatable, Hashable, Sendable {
  public let id = UUID()
  public let timeRange: String
  public let dateInterval: DateInterval?
  public let title: String
  public let speaker: String
  public let speakerID: Speaker.ID?
  public let tags: String?
  public let description: String?
  public let isRecording: Bool?
  public let isWorkshop: Bool
  public let hackMDURL: URL?

  public init(
    date: Date,
    timeRange: String,
    title: String,
    speaker: String,
    speakerID: Speaker.ID?,
    tags: String?,
    description: String?,
    hackMDURL: URL?,
    isRecording: Bool? = nil,
    isWorkshop: Bool = false
  ) {
    self.timeRange = timeRange
    self.dateInterval = Self.parseDateInterval(from: timeRange, baseDate: date)
    self.title = title
    self.speaker = speaker
    self.speakerID = speakerID
    self.tags = tags
    self.description = description?.decodedSessionDataLineBreaks
    self.isRecording = isRecording
    self.isWorkshop = isWorkshop
    self.hackMDURL = hackMDURL
  }

  public init(date: Date, session: Session, isWorkshop: Bool = false) {
    self.timeRange = session.time
    self.dateInterval = Self.parseDateInterval(from: session.time, baseDate: date)
    self.title = session.title
    self.speaker = session.speaker
    self.speakerID = session.speakerID
    self.tags = session.tags.isEmpty ? nil : session.tags.joined(separator: " · ")
    self.description =
      session.description.isEmpty ? nil : session.description.decodedSessionDataLineBreaks
    self.isRecording = session.isRecording
    self.isWorkshop = isWorkshop
    self.hackMDURL = session.hackMD
  }

  public init(date: Date, scheduledSession: ScheduledSession) {
    self.init(
      date: date,
      session: scheduledSession.session,
      isWorkshop: scheduledSession.isWorkshop
    )
  }

  public init(session: Session, isWorkshop: Bool = false) {
    self.timeRange = session.time
    self.dateInterval = nil
    self.title = session.title
    self.speaker = session.speaker
    self.speakerID = session.speakerID
    self.tags = session.tags.isEmpty ? nil : session.tags.joined(separator: " · ")
    self.description =
      session.description.isEmpty ? nil : session.description.decodedSessionDataLineBreaks
    self.isRecording = session.isRecording
    self.isWorkshop = isWorkshop
    self.hackMDURL = session.hackMD
  }

  public init(
    timeRange: String,
    title: String,
    speaker: String,
    speakerID: Speaker.ID?,
    tags: String?,
    description: String?,
    hackMDURL: URL?,
    isRecording: Bool? = nil,
    isWorkshop: Bool = false
  ) {
    self.timeRange = timeRange
    self.dateInterval = nil
    self.title = title
    self.speaker = speaker
    self.speakerID = speakerID
    self.tags = tags
    self.description = description?.decodedSessionDataLineBreaks
    self.isRecording = isRecording
    self.isWorkshop = isWorkshop
    self.hackMDURL = hackMDURL
  }

  private static func parseDateInterval(from timeRange: String, baseDate: Date) -> DateInterval? {
    let trimmed = timeRange.trimmingCharacters(in: .whitespaces)

    let separators = [" – ", " - ", " — ", "–", "-", "—"]
    var components: [String] = []

    for separator in separators {
      if trimmed.contains(separator) {
        components = trimmed.components(separatedBy: separator)
        break
      }
    }

    guard components.count == 2 else { return nil }

    let startTimeString = components[0].trimmingCharacters(in: .whitespaces)
    let endTimeString = components[1].trimmingCharacters(in: .whitespaces)

    guard let startTime = parseTime(startTimeString),
      let endTime = parseTime(endTimeString)
    else { return nil }

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

    let baseDateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)

    var startDateComponents = baseDateComponents
    startDateComponents.hour = startTime.hour
    startDateComponents.minute = startTime.minute

    var endDateComponents = baseDateComponents
    endDateComponents.hour = endTime.hour
    endDateComponents.minute = endTime.minute

    if endTime.hour < startTime.hour {
      endDateComponents.day = (endDateComponents.day ?? 0) + 1
    }

    guard let startDate = calendar.date(from: startDateComponents),
      let endDate = calendar.date(from: endDateComponents)
    else { return nil }

    return DateInterval(start: startDate, end: endDate)
  }

  private static func parseTime(_ timeString: String) -> (hour: Int, minute: Int)? {
    let components = timeString.components(separatedBy: ":")
    guard components.count == 2,
      let hour = Int(components[0]),
      let minute = Int(components[1]),
      hour >= 0 && hour <= 23,
      minute >= 0 && minute <= 59
    else { return nil }

    return (hour: hour, minute: minute)
  }
}
