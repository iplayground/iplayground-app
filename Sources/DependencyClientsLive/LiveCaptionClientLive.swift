import Dependencies
import DependencyClients
import Foundation
import Models

extension LiveCaptionClient: DependencyKey {
  public static let liveValue = Self(
    captionConnection: { trackNumber in
      AsyncThrowingStream { continuation in
        let task = Task {
          while !Task.isCancelled {
            continuation.yield(.connecting)

            do {
              let negotiation = try await LiveCaptionRelay.negotiate(trackNumber: trackNumber)
              continuation.yield(.connected(expiresAt: negotiation.expiresAt))

              try await LiveCaptionRelay.receiveEvents(
                url: negotiation.url,
                expiresAt: negotiation.expiresAt,
                continuation: continuation
              )
            } catch is CancellationError {
              break
            } catch {
              continuation.yield(.failed(error.localizedDescription))
              continuation.yield(.disconnected)
              try? await Task.sleep(for: .seconds(3))
            }
          }

          continuation.finish()
        }

        continuation.onTermination = { _ in
          task.cancel()
        }
      }
    }
  )
}

private enum LiveCaptionRelay {
  private static let baseURL = URL(string: "https://livecaption-relay.iplayground.io")!
  private static let refreshLeadTime: TimeInterval = 5 * 60

  static func negotiate(trackNumber: Int) async throws -> NegotiationResponse {
    var url = baseURL
    url.append(path: "api/viewer/negotiate")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(NegotiateRequest(trackNumber: trackNumber))

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
      (200..<300).contains(httpResponse.statusCode)
    else {
      throw LiveCaptionRelayError.negotiateFailed
    }

    return try LiveCaptionJSON.decode(NegotiationResponse.self, from: data)
  }

  static func receiveEvents(
    url: URL,
    expiresAt: Date,
    continuation: AsyncThrowingStream<LiveCaptionStreamAction, Error>.Continuation
  ) async throws {
    let webSocket = URLSession.shared.webSocketTask(with: url)
    webSocket.resume()
    defer {
      webSocket.cancel(with: .goingAway, reason: nil)
    }

    try await withTaskCancellationHandler {
      while !Task.isCancelled {
        let refreshDate = expiresAt.addingTimeInterval(-refreshLeadTime)
        let secondsUntilRefresh = max(1, refreshDate.timeIntervalSinceNow)
        let result = try await receiveOrRefresh(
          webSocket: webSocket,
          seconds: secondsUntilRefresh
        )

        switch result {
        case let .event(event):
          continuation.yield(.event(event))

        case .refreshDue:
          continuation.yield(.disconnected)
          return
        }
      }
    } onCancel: {
      webSocket.cancel(with: .goingAway, reason: nil)
    }
  }

  private static func receiveOrRefresh(
    webSocket: URLSessionWebSocketTask,
    seconds: TimeInterval
  ) async throws -> ReceiveResult {
    try await withThrowingTaskGroup(of: ReceiveResult.self) { group in
      group.addTask {
        .event(try await decode(message: webSocket.receive()))
      }
      group.addTask {
        try await Task.sleep(for: .milliseconds(Int64(seconds * 1000)))
        webSocket.cancel(with: .goingAway, reason: nil)
        return .refreshDue
      }

      let result = try await group.next() ?? .refreshDue
      group.cancelAll()
      return result
    }
  }

  private static func decode(message: URLSessionWebSocketTask.Message) throws
    -> LiveCaptionServerEvent
  {
    switch message {
    case let .string(string):
      guard let data = string.data(using: .utf8) else {
        throw LiveCaptionRelayError.invalidMessage
      }
      return try LiveCaptionServerEvent.decode(from: data)

    case let .data(data):
      return try LiveCaptionServerEvent.decode(from: data)

    @unknown default:
      throw LiveCaptionRelayError.invalidMessage
    }
  }
}

private struct NegotiateRequest: Encodable {
  var trackNumber: Int
}

private struct NegotiationResponse: Decodable {
  var url: URL
  var expiresAt: Date
}

private enum ReceiveResult {
  case event(LiveCaptionServerEvent)
  case refreshDue
}

private enum LiveCaptionRelayError: Error {
  case invalidMessage
  case negotiateFailed
}
