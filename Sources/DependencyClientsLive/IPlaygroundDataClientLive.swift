import Dependencies
import DependenciesMacros
import DependencyClients
import Foundation
import IdentifiedCollections
import SessionData

extension IPlaygroundDataClient: DependencyKey {
  public static let liveValue: IPlaygroundDataClient = {
    let dataLanguage = DataLanguage(localeIdentifier: Locale.preferredLanguages.first ?? "en")
    return .sessionDataValue(dataLanguage: dataLanguage)
  }()
}
