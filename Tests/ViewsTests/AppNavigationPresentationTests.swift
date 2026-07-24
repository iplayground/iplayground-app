import XCTest

@testable import Views

@MainActor
final class AppNavigationPresentationTests: XCTestCase {
  func testActivityTabPresentation() {
    XCTAssertEqual(AppNavigationTitle.activity.rawValue, "活動")
    XCTAssertEqual(HomeTabPresentation.activitySymbol, "flag.pattern.checkered")
  }

  func testScheduleNavigationTitle() {
    XCTAssertEqual(AppNavigationTitle.scheduleAndWorkshops.rawValue, "議程與工作坊")
  }

  func testSpeakerNavigationTitle() {
    XCTAssertEqual(AppNavigationTitle.speaker.rawValue, "講者")
  }

}
