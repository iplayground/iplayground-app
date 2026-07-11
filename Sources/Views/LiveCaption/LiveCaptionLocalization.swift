import Models
import SwiftUI

extension LiveCaptionMode {
  package var localizedDisplayName: String {
    switch self {
    case .accurate:
      return String(localized: "精準", bundle: .module)
    case .fast:
      return String(localized: "快速", bundle: .module)
    default:
      return rawValue
    }
  }
}

extension LiveCaptionLanguage {
  package var localizedDisplayName: String {
    switch self {
    case .zhHant:
      return String(localized: "繁體中文", bundle: .module)
    case .en:
      return String(localized: "英文", bundle: .module)
    case .ja:
      return String(localized: "日文", bundle: .module)
    case .ko:
      return String(localized: "韓文", bundle: .module)
    default:
      return rawValue
    }
  }
}
