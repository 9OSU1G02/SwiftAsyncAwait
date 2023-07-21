//
//  TimeoutTask.swift
//  BlabberTests
//
//  Created by Quốc Huy Nguyễn on 7/20/23.
//

import Foundation

class TimeoutTask<Success> {
  let seconds: Int
  let operation: @Sendable () async throws -> Success
  private var continuation: CheckedContinuation<Success, Error>?

  var value: Success {
    get async throws {
      try await withCheckedThrowingContinuation { continuation in
        self.continuation = continuation
        Task {
          try await Task.sleep(for: .seconds(seconds))
          self.continuation?.resume(throwing: TimeoutError())
          self.continuation = nil
        }
        Task {
          let result = try await operation()
          self.continuation?.resume(returning: result)
          self.continuation = nil
        }
      }
    }
  }

  init(
    seconds: Int,
    operation: @escaping @Sendable () async throws -> Success
  ) {
    self.seconds = seconds
    self.operation = operation
  }

  func cancel() {
    continuation?.resume(throwing: CancellationError())
    continuation = nil
  }
}

extension TimeoutTask {
  struct TimeoutError: LocalizedError {
    var errorDescription: String? {
      return "The operation timed out."
    }
  }
}
