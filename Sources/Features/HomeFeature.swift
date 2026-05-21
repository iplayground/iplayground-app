import ComposableArchitecture
import DependencyClients
import Foundation
import Models

@Reducer
package struct HomeFeature {
  @ObservableState
  package struct State: Equatable {
    @SharedReader(.day1Sessions) package var day1Sessions: [SessionWrapper] = []
    @SharedReader(.day2Sessions) package var day2Sessions: [SessionWrapper] = []
    @Shared(.speakers) package var speakers: IdentifiedArrayOf<Speaker> = []
    @Shared(.sponsorData) package var sponsorData: SponsorsData = SponsorsData(
      sponsors: [], personal: [], partner: [])
    @Shared(.staffs) package var staffs: [Staff] = []
    @Shared(.links) package var links: [Link] = []

    package var today = TodayFeature.State()
    package var community = CommunityFeature.State()
    package var my = MyFeature.State()
    package var about = AboutFeature.State()

    package init() {}
  }

  package enum Action: Equatable, BindableAction {
    case today(TodayFeature.Action)
    case community(CommunityFeature.Action)
    case my(MyFeature.Action)
    case about(AboutFeature.Action)
    case binding(BindingAction<State>)
    case task
    case setSpeakers(IdentifiedArrayOf<Speaker>)
    case setSponsorData(SponsorsData)
    case setStaffs([Staff])
    case setLinks([Link])
  }

  package init() {}

  package var body: some ReducerOf<Self> {
    Scope(state: \.today, action: \.today) {
      TodayFeature()
    }
    Scope(state: \.community, action: \.community) {
      CommunityFeature()
    }
    Scope(state: \.my, action: \.my) {
      MyFeature()
    }
    Scope(state: \.about, action: \.about) {
      AboutFeature()
    }
    BindingReducer()
    Reduce(core)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .today:
      return .none

    case .community:
      return .none

    case .my:
      return .none

    case .about:
      return .none

    case .binding:
      return .none

    case let .setSpeakers(speakers):
      state.$speakers.withLock { $0 = speakers }
      return .none

    case let .setSponsorData(sponsorData):
      state.$sponsorData.withLock { $0 = sponsorData }
      return .none

    case let .setStaffs(staffs):
      state.$staffs.withLock { $0 = staffs }
      return .none

    case let .setLinks(links):
      state.$links.withLock { $0 = links }
      return .none

    case .task:
      return .run { send in
        await withThrowingTaskGroup(of: Void.self) { group in
          group.addTask {
            @Dependency(\.iPlaygroundDataClient) var client
            let cachedSpeakers = try await client.fetchSpeakers(.cacheFirst)
            async let remoteSpeakers = try await client.fetchSpeakers(.remote)

            await send(.setSpeakers(cachedSpeakers))

            let speakers = try await remoteSpeakers
            if speakers != cachedSpeakers {
              await send(.setSpeakers(speakers))
            }
          }
          group.addTask {
            @Dependency(\.iPlaygroundDataClient) var client
            let cachedSponsorData = try await client.fetchSponsors(.cacheFirst)
            async let remoteSponsorData = try await client.fetchSponsors(.remote)

            await send(.setSponsorData(cachedSponsorData))

            let sponsorData = try await remoteSponsorData
            if sponsorData != cachedSponsorData {
              await send(.setSponsorData(sponsorData))
            }
          }
          group.addTask {
            @Dependency(\.iPlaygroundDataClient) var client
            let cachedStaffs = try await client.fetchStaffs(.cacheFirst)
            async let remoteStaffs = try await client.fetchStaffs(.remote)

            await send(.setStaffs(cachedStaffs))

            let staffs = try await remoteStaffs
            if staffs != cachedStaffs {
              await send(.setStaffs(staffs))
            }
          }
          group.addTask {
            @Dependency(\.iPlaygroundDataClient) var client
            let cachedLinks = try await client.fetchLinks(.cacheFirst)
            async let remoteLinks = try await client.fetchLinks(.remote)

            await send(.setLinks(cachedLinks))

            let links = try await remoteLinks
            if links != cachedLinks {
              await send(.setLinks(links))
            }
          }
        }
      }
    }
  }
}
