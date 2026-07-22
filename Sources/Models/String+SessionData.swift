import Foundation

extension String {
  public var decodedSessionDataLineBreaks: String {
    replacingOccurrences(
      of: #"<br\s*/?>"#,
      with: "\n",
      options: [.regularExpression, .caseInsensitive]
    )
  }
}
