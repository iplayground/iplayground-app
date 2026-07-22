import CoreText
import Models
import SwiftUI

struct IPlaygroundWordmark: View {
  @Environment(\.iPlaygroundTheme) private var theme
  @ScaledMetric(relativeTo: .title) private var markFontSize = 24
  @ScaledMetric(relativeTo: .title) private var yearFontSize = 27

  init() {
    IPlaygroundFontRegistrar.registerFonts()
  }

  var body: some View {
    VStack(alignment: .center, spacing: 6) {
      Text(verbatim: "IPLAYGROUND")
        .font(.custom("Michroma", size: markFontSize, relativeTo: .title))
        .foregroundStyle(theme.wordmarkForeground)

      Text(verbatim: IPlaygroundEvent.yearString)
        .font(.custom("Michroma", size: yearFontSize, relativeTo: .title))
        .foregroundStyle(theme.wordmarkYear)
    }
    .lineLimit(1)
    .minimumScaleFactor(0.55)
    .accessibilityLabel(Text(verbatim: "iPlayground \(IPlaygroundEvent.yearString)"))
  }
}

private enum IPlaygroundFontRegistrar {
  static func registerFonts() {
    _ = registerOnce
  }

  private static let registerOnce: Void = {
    let fontURL =
      Bundle.module.url(
        forResource: "Michroma-Regular",
        withExtension: "ttf",
        subdirectory: "Fonts")
      ?? Bundle.module.url(forResource: "Michroma-Regular", withExtension: "ttf")

    guard let fontURL else {
      return
    }

    _ = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
  }()
}

#Preview {
  VStack(spacing: 32) {
    IPlaygroundWordmark()
      .environment(\.iPlaygroundTheme, .y2026)

    IPlaygroundWordmark()
      .environment(\.iPlaygroundTheme, .y2025)
  }
  .padding()
}
