

import Foundation

/// Easily throw generic errors with a text description.
extension String: Error { }

/// The app model that communicates with the server.
class LittleJohnModel: ObservableObject {
  /// Current live updates.
  @Published private(set) var tickerSymbols: [Stock] = []

  /// Start live updates for the provided stock symbols.
  func startTicker(_ selectedSymbols: [String]) async throws {
    guard let url = URL(string: "http://localhost:8080/littlejohn/ticker?\(selectedSymbols.joined(separator: ","))") else {
      throw "The URL could not be created."
    }
  }

  /// A URL session that lets requests run indefinitely so we can receive live updates from server.
  private lazy var liveURLSession: URLSession = {
    var configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = .infinity
    return URLSession(configuration: configuration)
  }()
}
