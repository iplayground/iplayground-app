import Foundation

public struct LiveCaptionMode: RawRepresentable, Codable, Equatable, Hashable, Identifiable,
  Sendable
{
  public static let accurate = Self(rawValue: "accurate")
  public static let fast = Self(rawValue: "fast")
  public static let allCases: [Self] = [.accurate, .fast]

  public let rawValue: String
  public var id: String { rawValue }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(rawValue: try container.decode(String.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct LiveCaptionLanguage: RawRepresentable, Codable, Equatable, Hashable, Identifiable,
  Sendable
{
  public static let zhHant = Self(rawValue: "zh-Hant")
  public static let en = Self(rawValue: "en")
  public static let ja = Self(rawValue: "ja")
  public static let ko = Self(rawValue: "ko")
  public static let allCases: [Self] = [.zhHant, .en, .ja, .ko]

  public let rawValue: String
  public var id: String { rawValue }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(rawValue: try container.decode(String.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public enum LiveCaptionPortalStatus: String, Codable, Equatable, Sendable {
  case online
  case offline
}

public enum LiveCaptionSessionStatus: String, Codable, Equatable, Sendable {
  case started
  case stopped
}

public enum LiveCaptionControlEventName: String, Codable, Equatable, Sendable {
  case portalStatus
  case sessionStatus
  case captionAvailability
}

public struct LiveCaptionControlEvent: Codable, Equatable, Sendable {
  public let event: LiveCaptionControlEventName
  public let status: String?
  public let sessionId: String?
  public let availableCaptionModes: [LiveCaptionMode]?
  public let availableLanguages: [LiveCaptionLanguage]?
  public let updatedAt: Date?

  public init(
    event: LiveCaptionControlEventName,
    status: String? = nil,
    sessionId: String? = nil,
    availableCaptionModes: [LiveCaptionMode]? = nil,
    availableLanguages: [LiveCaptionLanguage]? = nil,
    updatedAt: Date? = nil
  ) {
    self.event = event
    self.status = status
    self.sessionId = sessionId
    self.availableCaptionModes = availableCaptionModes
    self.availableLanguages = availableLanguages
    self.updatedAt = updatedAt
  }

  public var portalStatus: LiveCaptionPortalStatus? {
    guard event == .portalStatus, let status else { return nil }
    return LiveCaptionPortalStatus(rawValue: status)
  }

  public var sessionStatus: LiveCaptionSessionStatus? {
    guard event == .sessionStatus, let status else { return nil }
    return LiveCaptionSessionStatus(rawValue: status)
  }
}

public struct LiveCaptionItem: Codable, Equatable, Identifiable, Sendable {
  public let sessionId: String
  public let sequence: Int
  public let captionMode: LiveCaptionMode
  public let createdAt: Date?
  public let offsetTicks: Int64?
  public let durationTicks: Int64?
  public let captions: [String: String]

  public var id: String {
    "\(sessionId)-\(sequence)-\(captionMode.rawValue)"
  }

  public init(
    sessionId: String,
    sequence: Int,
    captionMode: LiveCaptionMode,
    createdAt: Date? = nil,
    offsetTicks: Int64? = nil,
    durationTicks: Int64? = nil,
    captions: [String: String]
  ) {
    self.sessionId = sessionId
    self.sequence = sequence
    self.captionMode = captionMode
    self.createdAt = createdAt
    self.offsetTicks = offsetTicks
    self.durationTicks = durationTicks
    self.captions = captions
  }

  public func text(for language: LiveCaptionLanguage) -> String? {
    captions[language.rawValue]
  }
}

public enum LiveCaptionServerEvent: Equatable, Sendable {
  case control(LiveCaptionControlEvent)
  case caption(LiveCaptionItem)
}

extension LiveCaptionServerEvent: Decodable {
  private enum CodingKeys: String, CodingKey {
    case type
  }

  private enum EventType: String, Decodable {
    case control
    case caption
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(EventType.self, forKey: .type)

    switch type {
    case .control:
      self = .control(try LiveCaptionControlEvent(from: decoder))
    case .caption:
      self = .caption(try LiveCaptionItem(from: decoder))
    }
  }
}

extension LiveCaptionServerEvent {
  public static func decode(from data: Data) throws -> Self {
    try LiveCaptionJSON.decode(Self.self, from: data)
  }
}

public enum LiveCaptionJSON {
  public static func decode<Value: Decodable>(
    _ type: Value.Type,
    from data: Data
  ) throws -> Value {
    try makeDecoder().decode(type, from: data)
  }

  private static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)

      if let date = iso8601Date(
        from: string,
        formatOptions: [.withInternetDateTime, .withFractionalSeconds]
      ) ?? iso8601Date(from: string, formatOptions: [.withInternetDateTime]) {
        return date
      }

      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid ISO 8601 date: \(string)"
      )
    }
    return decoder
  }

  private static func iso8601Date(
    from string: String,
    formatOptions: ISO8601DateFormatter.Options
  ) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = formatOptions
    return formatter.date(from: string)
  }
}
