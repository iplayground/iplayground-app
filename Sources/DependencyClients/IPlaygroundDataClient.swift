import Dependencies
import DependenciesMacros
import IdentifiedCollections
import Models
import SessionData

@DependencyClient
public struct IPlaygroundDataClient: Sendable {
  public var fetchSchedules:
    @Sendable (_ day: Int?, _ strategy: FetchStrategy) async throws -> [Session]
  public var fetchAgenda:
    @Sendable (_ day: Int?, _ strategy: FetchStrategy) async throws -> [ScheduledSession]
  public var fetchSpeakers:
    @Sendable (_ strategy: FetchStrategy) async throws -> IdentifiedArrayOf<Speaker>
  public var fetchSponsors: @Sendable (_ strategy: FetchStrategy) async throws -> SponsorsData
  public var fetchStaffs: @Sendable (_ strategy: FetchStrategy) async throws -> [Staff]
  public var fetchLinks: @Sendable (_ strategy: FetchStrategy) async throws -> [Link]
}

extension IPlaygroundDataClient: TestDependencyKey {
  public static let testValue = Self()
  public static let previewValue: IPlaygroundDataClient = {
    .sessionDataValue(dataLanguage: .traditionalChinese, forcedStrategy: .localOnly)
  }()
}

extension IPlaygroundDataClient {
  public static func sessionDataValue(
    dataLanguage: DataLanguage,
    client: SessionDataClient = .live,
    forcedStrategy: FetchStrategy? = nil
  ) -> IPlaygroundDataClient {
    IPlaygroundDataClient(
      fetchSchedules: { day, strategy in
        let schedule = try await client.fetchSchedules(
          dataLanguage: dataLanguage,
          strategy: forcedStrategy ?? strategy
        )
        return schedule.sessions(for: day)
      },
      fetchAgenda: { day, strategy in
        let schedule = try await client.fetchSchedules(
          dataLanguage: dataLanguage,
          strategy: forcedStrategy ?? strategy
        )
        return schedule.scheduledSessions(for: day)
      },
      fetchSpeakers: { strategy in
        let speakers = try await client.fetchSpeakers(
          dataLanguage: dataLanguage,
          strategy: forcedStrategy ?? strategy
        )
        return IdentifiedArrayOf(uniqueElements: speakers)
      },
      fetchSponsors: { strategy in
        try await client.fetchSponsors(strategy: forcedStrategy ?? strategy)
      },
      fetchStaffs: { strategy in
        try await client.fetchStaffs(strategy: forcedStrategy ?? strategy)
      },
      fetchLinks: { strategy in
        try await client.fetchLinks(strategy: forcedStrategy ?? strategy)
      }
    )
  }
}

extension Schedule {
  fileprivate func sessions(for day: Int?) -> [Session] {
    switch day {
    case 1:
      return day1
    case 2:
      return day2
    case nil:
      return day1 + day2
    default:
      return []
    }
  }

  fileprivate func scheduledSessions(for day: Int?) -> [ScheduledSession] {
    switch day {
    case 1:
      return ScheduledSession.merged(sessions: day1, workshops: workshopDay1)
    case 2:
      return ScheduledSession.merged(sessions: day2, workshops: workshopDay2)
    case nil:
      return ScheduledSession.merged(sessions: day1, workshops: workshopDay1)
        + ScheduledSession.merged(sessions: day2, workshops: workshopDay2)
    default:
      return []
    }
  }
}

extension DependencyValues {
  public var iPlaygroundDataClient: IPlaygroundDataClient {
    get { self[IPlaygroundDataClient.self] }
    set { self[IPlaygroundDataClient.self] = newValue }
  }
}
