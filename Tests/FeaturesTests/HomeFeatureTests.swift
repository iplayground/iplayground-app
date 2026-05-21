import ComposableArchitecture
import DependencyClients
import Features
import Models
import XCTest

@MainActor
final class HomeFeatureTests: XCTestCase {
  func testTask() async throws {
    let cachedSpeakers = IdentifiedArrayOf<Speaker>(uniqueElements: [
      createMockSpeaker(id: 1, name: "Cached Speaker")
    ])
    let remoteSpeakers = IdentifiedArrayOf<Speaker>(uniqueElements: [
      createMockSpeaker(id: 1, name: "Remote Speaker"),
      createMockSpeaker(id: 2, name: "Remote Speaker 2"),
    ])

    let cachedSponsors = SponsorsData(sponsors: [], personal: [], partner: [])
    let remoteSponsors = SponsorsData(sponsors: [], personal: [], partner: [])

    let cachedStaffs = [createMockStaff(name: "Cached Staff")]
    let remoteStaffs = [createMockStaff(name: "Remote Staff")]

    let cachedLinks = [
      Link(
        id: "cached", title: "Cached Link", url: URL(string: "https://cached.com")!, icon: "globe",
        type: .primary)
    ]
    let remoteLinks = [
      Link(
        id: "website", title: "官網", url: URL(string: "https://iplayground.io")!, icon: "globe",
        type: .primary),
      Link(
        id: "youtube", title: "YouTube", url: URL(string: "https://youtube.com/@iplayground")!,
        icon: "play.rectangle", type: .primary),
    ]

    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.iPlaygroundDataClient.fetchSpeakers = { strategy in
        switch strategy {
        case .cacheFirst: return cachedSpeakers
        case .remote: return remoteSpeakers
        case .localOnly: return cachedSpeakers
        }
      }
      $0.iPlaygroundDataClient.fetchSponsors = { strategy in
        switch strategy {
        case .cacheFirst: return cachedSponsors
        case .remote: return remoteSponsors
        case .localOnly: return cachedSponsors
        }
      }
      $0.iPlaygroundDataClient.fetchStaffs = { strategy in
        switch strategy {
        case .cacheFirst: return cachedStaffs
        case .remote: return remoteStaffs
        case .localOnly: return cachedStaffs
        }
      }
      $0.iPlaygroundDataClient.fetchLinks = { strategy in
        switch strategy {
        case .cacheFirst: return cachedLinks
        case .remote: return remoteLinks
        case .localOnly: return cachedLinks
        }
      }
    }

    store.exhaustivity = .off  // skip changes of binding since the order is not deterministic
    await store.send(\.task)
    await store.skipReceivedActions(strict: false)

    // Verify final state has remote data
    expectNoDifference(store.state.speakers, remoteSpeakers)
    expectNoDifference(store.state.sponsorData.sponsors, remoteSponsors.sponsors)
    expectNoDifference(store.state.sponsorData.partner, remoteSponsors.partner)
    expectNoDifference(store.state.staffs, remoteStaffs)
    expectNoDifference(store.state.links, remoteLinks)
  }

  func testTaskWithSameData() async throws {
    let speakers = IdentifiedArrayOf<Speaker>(uniqueElements: [
      createMockSpeaker(id: 1, name: "Same Speaker")
    ])
    let sponsors = SponsorsData(sponsors: [], personal: [], partner: [])
    let staffs = [createMockStaff(name: "Same Staff")]
    let links = [
      Link(
        id: "same", title: "Same Link", url: URL(string: "https://same.com")!, icon: "globe",
        type: .primary)
    ]

    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.iPlaygroundDataClient.fetchSpeakers = { strategy in
        switch strategy {
        case .cacheFirst, .remote, .localOnly: return speakers
        }
      }
      $0.iPlaygroundDataClient.fetchSponsors = { strategy in
        switch strategy {
        case .cacheFirst, .remote, .localOnly: return sponsors
        }
      }
      $0.iPlaygroundDataClient.fetchStaffs = { strategy in
        switch strategy {
        case .cacheFirst, .remote, .localOnly: return staffs
        }
      }
      $0.iPlaygroundDataClient.fetchLinks = { strategy in
        switch strategy {
        case .cacheFirst, .remote, .localOnly: return links
        }
      }
    }

    store.exhaustivity = .off
    await store.send(\.task)
    await store.skipReceivedActions(strict: false)

    // Verify final state
    expectNoDifference(store.state.speakers, speakers)
    expectNoDifference(store.state.sponsorData.sponsors, sponsors.sponsors)
    expectNoDifference(store.state.staffs, staffs)
    expectNoDifference(store.state.links, links)
  }

  // MARK: - Helper Methods

  private func createMockSpeaker(
    id: Int = 1,
    name: String = "Test Speaker",
    title: String? = "Test Title",
    intro: String = "Test introduction"
  ) -> Speaker {
    return Speaker(
      id: id,
      name: name,
      title: title,
      intro: intro,
      photo: nil,
      url: nil,
      fb: nil,
      github: nil,
      linkedin: nil,
      threads: nil,
      x: nil,
      ig: nil
    )
  }

  private func createMockStaff(
    name: String = "Test Staff",
    title: String? = "Test Title",
    photo: URL? = nil,
    url: URL? = nil
  ) -> Staff {
    return Staff(
      name: name,
      title: title,
      photo: photo,
      url: url
    )
  }

}
