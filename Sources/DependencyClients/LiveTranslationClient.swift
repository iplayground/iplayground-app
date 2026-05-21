import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct LiveTranslationClient: Sendable {
  public var getLangSet: @Sendable (_ langCode: String) async throws -> LangSet = { _ in
    LangSet(data: [:])
  }
  public var getLangList: @Sendable () async throws -> [LanguageItem] = { [] }
  public var getChatRoomInfo: @Sendable (_ roomNumber: String) async throws -> ChatRoomInfo = { _ in
    ChatRoomInfo(chatRoomID: "", chatRoomTitle: "")
  }
  public var chatConnection:
    @Sendable (_ roomNumber: String) -> AsyncThrowingStream<StreamAction, Error> = { _ in
      AsyncThrowingStream { _ in }
    }
  public var requestBatchTranslation:
    @Sendable (_ data: [TranslationRequest]) async throws -> Void = { _ in }
}

public struct LangSet: Equatable, Sendable {
  public let data: [String: String]

  public init(data: [String: String]) {
    self.data = data
  }

  public func langCodingKey(_ langCode: String) -> String? {
    data[langCode]
  }
}

public struct LanguageItem: Equatable, Identifiable, Sendable {
  public let id: String
  public let langCode: String
  public let name: String

  public init(id: String, langCode: String, name: String) {
    self.id = id
    self.langCode = langCode
    self.name = name
  }
}

public struct ChatRoomInfo: Equatable, Sendable {
  public let chatRoomID: String
  public let chatRoomTitle: String

  public init(chatRoomID: String, chatRoomTitle: String) {
    self.chatRoomID = chatRoomID
    self.chatRoomTitle = chatRoomTitle
  }
}

public struct CompositeChatItem: Equatable, Identifiable, Sendable {
  public let id: String
  public let chatId: String
  public let text: String
  public let translatedText: String?
  public let srcLangCode: String
  public let dstLangCode: String
  public let timestamp: String

  public init(
    id: String,
    chatId: String,
    text: String,
    translatedText: String?,
    srcLangCode: String,
    dstLangCode: String,
    timestamp: String
  ) {
    self.id = id
    self.chatId = chatId
    self.text = text
    self.translatedText = translatedText
    self.srcLangCode = srcLangCode
    self.dstLangCode = dstLangCode
    self.timestamp = timestamp
  }
}

public struct TranslationRequest: Equatable, Sendable {
  public let chatRoomID: String
  public let chatID: String
  public let srcLangCode: String
  public let dstLangCode: String
  public let timestamp: String
  public let text: String

  public init(
    chatRoomID: String,
    chatID: String,
    srcLangCode: String,
    dstLangCode: String,
    timestamp: String,
    text: String
  ) {
    self.chatRoomID = chatRoomID
    self.chatID = chatID
    self.srcLangCode = srcLangCode
    self.dstLangCode = dstLangCode
    self.timestamp = timestamp
    self.text = text
  }
}

public enum StreamAction: Equatable, Sendable {
  case connect
  case disconnect
  case peerClosed
  case responseChat(CompositeChatItem)
  case responseBatchTranslation([CompositeChatItem])
}

extension LiveTranslationClient: TestDependencyKey {
  public static let testValue = Self()

  public static let previewValue = Self(
    getLangSet: { _ in
      LangSet(data: ["en": "English", "zh": "中文", "ja": "日本語"])
    },
    getLangList: {
      [
        LanguageItem(id: "en", langCode: "en", name: "English"),
        LanguageItem(id: "zh", langCode: "zh", name: "中文"),
        LanguageItem(id: "ja", langCode: "ja", name: "日本語"),
      ]
    },
    getChatRoomInfo: { _ in
      ChatRoomInfo(
        chatRoomID: "490294",
        chatRoomTitle: "iPlayground 2026"
      )
    },
    chatConnection: { _ in
      AsyncThrowingStream { continuation in
        continuation.yield(.connect)
        continuation.yield(
          .responseChat(
            CompositeChatItem(
              id: "1",
              chatId: "1",
              text: "Hello World",
              translatedText: nil,
              srcLangCode: "en",
              dstLangCode: "zh",
              timestamp: "\(Date().timeIntervalSince1970)"
            )
          ))
      }
    },
    requestBatchTranslation: { _ in }
  )
}

extension DependencyValues {
  public var liveTranslationClient: LiveTranslationClient {
    get { self[LiveTranslationClient.self] }
    set { self[LiveTranslationClient.self] = newValue }
  }
}
