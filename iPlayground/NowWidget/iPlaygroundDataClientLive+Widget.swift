//
//  iPlaygroundDataClientLive.swift
//  iPlayground
//
//  Created by ethanhuang on 2025/8/28.
//

import Dependencies
import DependenciesMacros
import DependencyClients
import Foundation
import IdentifiedCollections
import SessionData

extension IPlaygroundDataClient: @retroactive DependencyKey {
  public static let liveValue: IPlaygroundDataClient = {
    let dataLanguage = DataLanguage(localeIdentifier: Locale.preferredLanguages.first ?? "en")
    return .sessionDataValue(dataLanguage: dataLanguage)
  }()
}
