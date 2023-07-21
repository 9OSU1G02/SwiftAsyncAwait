
@testable import Blabber
import XCTest

class BlabberTests: XCTestCase {
  @MainActor
  let model: BlabberModel = {
    let model = BlabberModel()
    model.username = "test"
    let testConfiguration = URLSessionConfiguration.default
    testConfiguration.protocolClasses = [TestURLProtocol.self]
    model.urlSession = .init(configuration: testConfiguration)
    model.sleep = { try await Task.sleep(for: .nanoseconds($0))}
    return model
  }()
  
  func testModelSay() async throws {
    try await model.say("Hello!")
    let request = try XCTUnwrap(TestURLProtocol.lastRequest)
    XCTAssertEqual(request.url?.absoluteString, "http://localhost:8080/chat/say")
    let httpBody = try XCTUnwrap(request.httpBody)
    let message = try XCTUnwrap(try? JSONDecoder()
      .decode(Message.self, from: httpBody))
      
    XCTAssertEqual(message.message, "Hello!")
  }
  
  func testModelCountdown() async throws {
    async let countdown: Void = model.countdown(to: "Tada!")
    async let messages = TimeoutTask(seconds: 10) {
      await TestURLProtocol.requests
        .prefix(4)
        .compactMap(\.httpBody)
        .compactMap { data in
          try? JSONDecoder()
            .decode(Message.self, from: data).message
        }
        .reduce(into: []) { result, request in
          result.append(request)
        }
    }
    .value
    let (messagesResult, _) = try await (messages, countdown)
    XCTAssertEqual(
      ["3", "2", "1", "🎉 Tada!"],
      messagesResult
    )
  }
}
