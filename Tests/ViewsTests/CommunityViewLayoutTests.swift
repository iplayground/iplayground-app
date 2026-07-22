import CustomDump
import Models
import SwiftUI
import XCTest

@testable import Views

@MainActor
final class CommunityViewLayoutTests: XCTestCase {
  func testSponsorPageUsesDarkColorScheme() {
    XCTAssertEqual(SponsorViewConfiguration.colorScheme, .dark)
  }

  func testSingleSponsorTierUsesGenericTitleIgnoringSpecialAndPartner() {
    let sections = SponsorSectionsData(
      SponsorsData(
        sponsors: [
          SponsorGroup(
            items: [SponsorItem(name: "Bronze", picture: nil, link: nil)],
            title: "青銅級"
          ),
          SponsorGroup(
            items: [SponsorItem(name: "Special", picture: nil, link: nil)],
            title: "特別贊助"
          ),
        ],
        personal: [],
        partner: [Partner(name: "Partner", icon: nil, link: nil)]
      )
    )

    expectNoDifference(sections.title(for: .bronze), .generic)
  }

  func testMultipleSponsorTiersKeepSpecificTitles() {
    let sections = SponsorSectionsData(
      SponsorsData(
        sponsors: [
          SponsorGroup(
            items: [SponsorItem(name: "Diamond", picture: nil, link: nil)],
            title: "鑽石級"
          ),
          SponsorGroup(
            items: [SponsorItem(name: "Silver", picture: nil, link: nil)],
            title: "白銀級"
          ),
          SponsorGroup(
            items: [SponsorItem(name: "Bronze", picture: nil, link: nil)],
            title: "青銅級"
          ),
        ],
        personal: [],
        partner: []
      )
    )

    expectNoDifference(sections.title(for: .diamond), .diamond)
    expectNoDifference(sections.title(for: .silver), .silver)
    expectNoDifference(sections.title(for: .bronze), .bronze)
  }

  func testSponsorSectionsExcludeEmptySections() {
    let sections = SponsorSectionsData(
      SponsorsData(
        sponsors: [
          SponsorGroup(items: [], title: "鑽石級"),
          SponsorGroup(items: [], title: "白銀級"),
          SponsorGroup(
            items: [SponsorItem(name: "Bronze", picture: nil, link: nil)],
            title: "青銅級"
          ),
          SponsorGroup(items: [], title: "特別贊助"),
        ],
        personal: [],
        partner: []
      )
    )

    expectNoDifference(sections.visibleSectionIDs, [.bronze])
  }
}
