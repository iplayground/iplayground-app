import Foundation
import SwiftUI

public enum IPlaygroundTheme: String, CaseIterable, Identifiable, Sendable {
  case y2026 = "2026"
  case y2025 = "2025"

  public static let defaultTheme = IPlaygroundTheme.y2026
  public static let storageKey = "iPlayground.theme"

  public var id: String { rawValue }
  public var displayName: String { rawValue }

  public var alternateAppIconName: String? {
    switch self {
    case .y2026:
      return nil
    case .y2025:
      return "AppIcon-2025"
    }
  }

  public init(storedValue: String?) {
    self = storedValue.flatMap(Self.init(rawValue:)) ?? Self.defaultTheme
  }
}

private struct IPlaygroundThemeKey: EnvironmentKey {
  static let defaultValue = IPlaygroundTheme.current
}

extension EnvironmentValues {
  public var iPlaygroundTheme: IPlaygroundTheme {
    get { self[IPlaygroundThemeKey.self] }
    set { self[IPlaygroundThemeKey.self] = newValue }
  }
}

extension IPlaygroundTheme {
  public static var current: Self {
    Self(storedValue: UserDefaults.standard.string(forKey: storageKey))
  }

  public var tint: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0x48513F, dark: 0xD2FF00)
    case .y2025:
      return .iplaygroundAdaptive(light: 0x4F7BFF, dark: 0x4F7BFF)
    }
  }

  public var primary: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0x48513F, dark: 0xD2FF00)
    case .y2025:
      return .iplaygroundAdaptive(light: 0x3B47DF, dark: 0x7B85FF)
    }
  }

  public var secondary: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0xC7692C, dark: 0xFEA668)
    case .y2025:
      return .iplaygroundAdaptive(light: 0xE6A500, dark: 0xFFD040)
    }
  }

  public var tertiary: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0x6D28D9, dark: 0x8B5CF6)
    case .y2025:
      return .iplaygroundAdaptive(light: 0xD4459A, dark: 0xFF79BD)
    }
  }

  public var wordmarkForeground: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0x0C1503, dark: 0xF4F5F1)
    case .y2025:
      return primary
    }
  }

  public var wordmarkYear: Color {
    switch self {
    case .y2026:
      return primary
    case .y2025:
      return secondary
    }
  }

  public var surface: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0xF0F3ED, dark: 0x282C20)
    case .y2025:
      return Color.gray.opacity(0.2)
    }
  }

  public var widgetBackground: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0xF9FBF7, dark: 0x14160F)
    case .y2025:
      return .iplaygroundAdaptive(light: 0xE8F0FF, dark: 0x2A4080)
    }
  }

  public var speakerBackground: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0xD2FF00, dark: 0x3A4500)
    case .y2025:
      return .iplaygroundAdaptive(light: 0x4B57EF, dark: 0x2D3670)
    }
  }

  public var sponsorBackground: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0xFEA668, dark: 0x5A2D00)
    case .y2025:
      return .iplaygroundAdaptive(light: 0xF8B801, dark: 0x8B6B00)
    }
  }

  public var staffBackground: Color {
    switch self {
    case .y2026:
      return .iplaygroundAdaptive(light: 0x8B5CF6, dark: 0x3C2478)
    case .y2025:
      return .iplaygroundAdaptive(light: 0xEE5FA7, dark: 0x7A3A5E)
    }
  }
}

extension Color {
  fileprivate static func iplaygroundAdaptive(light: UInt32, dark: UInt32) -> Color {
    #if canImport(UIKit)
      return Color(
        UIColor { traits in
          UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }
      )
    #elseif canImport(AppKit)
      return Color(
        NSColor(name: nil) { appearance in
          let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
          return NSColor(hex: isDark ? dark : light)
        }
      )
    #else
      return Color(hex: light)
    #endif
  }
}

#if canImport(UIKit)
  import UIKit

  extension UIColor {
    fileprivate convenience init(hex: UInt32) {
      self.init(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
      )
    }
  }
#endif

#if canImport(AppKit)
  import AppKit

  extension NSColor {
    fileprivate convenience init(hex: UInt32) {
      self.init(
        calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
      )
    }
  }
#endif
