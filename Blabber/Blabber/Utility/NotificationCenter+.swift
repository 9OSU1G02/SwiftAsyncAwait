
import Foundation

extension NotificationCenter {
  func notification(for name: Notification.Name) -> AsyncStream<Notification> {
    AsyncStream<Notification> { continuation in
      NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { notification in
        continuation.yield(notification)
      }
    }
  }
}
