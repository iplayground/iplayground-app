import Foundation
import Models
import Observation

#if os(iOS) || os(tvOS)
  import UIKit
#endif

@Observable
@MainActor
final class IPlaygroundThemeStore {
  var selectedTheme: IPlaygroundTheme

  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    self.selectedTheme = IPlaygroundTheme(
      storedValue: userDefaults.string(forKey: IPlaygroundTheme.storageKey))
    syncAppIcon(with: selectedTheme)
  }

  func selectTheme(_ theme: IPlaygroundTheme) {
    guard selectedTheme != theme else { return }

    selectedTheme = theme
    userDefaults.set(theme.rawValue, forKey: IPlaygroundTheme.storageKey)
    syncAppIcon(with: theme)
  }

  private func syncAppIcon(with theme: IPlaygroundTheme) {
    #if os(iOS) || os(tvOS)
      guard UIApplication.shared.supportsAlternateIcons else { return }

      let iconName = theme.alternateAppIconName
      guard UIApplication.shared.alternateIconName != iconName else { return }

      UIApplication.shared.setAlternateIconName(iconName)
    #endif
  }
}
