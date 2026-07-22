import Foundation

public enum IPlaygroundEvent {
  public static let year = 2026
  public static let yearString = String(year)

  public static let day1Date = date(month: 7, day: 25)
  public static let day2Date = date(month: 7, day: 26)

  public static func date(
    year: Int = Self.year,
    month: Int,
    day: Int,
    hour: Int = 0,
    minute: Int = 0
  ) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    return calendar.date(from: components)!
  }
}
