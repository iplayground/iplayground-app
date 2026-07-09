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

extension LiveCaptionMode {
  public var displayName: String {
    switch rawValue {
    case Self.accurate.rawValue:
      return String(localized: "精準")
    case Self.fast.rawValue:
      return String(localized: "快速")
    default:
      return rawValue
    }
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

extension LiveCaptionLanguage {
  public var displayName: String {
    switch rawValue {
    case Self.zhHant.rawValue:
      return String(localized: "繁體中文")
    case Self.en.rawValue:
      return String(localized: "英文")
    case Self.ja.rawValue:
      return String(localized: "日文")
    case Self.ko.rawValue:
      return String(localized: "韓文")
    default:
      return rawValue
    }
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
