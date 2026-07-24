import Dependencies
import DependenciesMacros
import DependencyClients
import IdentifiedCollections
import SessionData

extension IPlaygroundDataClient: DependencyKey {
  public static let liveValue = IPlaygroundDataClient.sessionDataValue(
    dataLanguage: .traditionalChinese
  )
}
