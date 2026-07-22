import Foundation
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

  func testNavigationCopyIsLocalizedForEverySupportedLocale() throws {
    let catalog = try loadCatalog()
    let expectedLocalizations = [
      "活動": [
        "en": "Event",
        "ja": "イベント",
        "ko": "이벤트",
        "zh-Hans": "活动",
      ],
      "議程與工作坊": [
        "en": "Schedule & Workshops",
        "ja": "スケジュールとワークショップ",
        "ko": "일정 및 워크숍",
        "zh-Hans": "议程与工作坊",
      ],
    ]

    XCTAssertEqual(catalog.sourceLanguage, "zh-Hant")
    XCTAssertNil(catalog.strings["我的"])
    XCTAssertNil(catalog.strings["議程與活動"])

    for (key, localizations) in expectedLocalizations {
      let entry = try XCTUnwrap(catalog.strings[key])
      XCTAssertEqual(entry.values, localizations)
    }
  }

  private func loadCatalog() throws -> StringCatalog {
    let repositoryURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    let catalogURL =
      repositoryURL
      .appendingPathComponent("Sources/Views/Resources/Localizable.xcstrings")

    return try JSONDecoder().decode(StringCatalog.self, from: Data(contentsOf: catalogURL))
  }
}

private struct StringCatalog: Decodable {
  let sourceLanguage: String
  let strings: [String: StringCatalogEntry]
}

private struct StringCatalogEntry: Decodable {
  let localizations: [String: StringCatalogLocalization]?

  var values: [String: String] {
    localizations?.mapValues(\.stringUnit.value) ?? [:]
  }
}

private struct StringCatalogLocalization: Decodable {
  let stringUnit: StringCatalogStringUnit
}

private struct StringCatalogStringUnit: Decodable {
  let value: String
}
