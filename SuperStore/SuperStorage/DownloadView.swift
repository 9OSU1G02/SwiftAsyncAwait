

import Combine
import SwiftUI
import UIKit
/// The file download view.
struct DownloadView: View {
  @State var timerTask: Task<Void, Error>?
  /// The selected file.
  let file: DownloadFile
  @EnvironmentObject var model: SuperStorageModel
  /// The downloaded data.
  @State var fileData: Data?
  /// Should display a download activity indicator.
  @State var isDownloadActive = false

  @State var duration = ""
  @State var downloadTask: Task<Void, Error>? {
    didSet {
      timerTask?.cancel()
      guard isDownloadActive else { return }
      let startTime = Date().timeIntervalSince1970
      let timerSequence = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .map { date -> String in
          let duration = Int(date.timeIntervalSince1970 - startTime)
          return "\(duration)s"
        }
        .values
      timerTask = Task {
        for await duration in timerSequence {
          self.duration = duration
        }
      }
    }
  }

  var body: some View {
    List {
      // Show the details of the selected file and download buttons.
      FileDetails(
        file: file,
        isDownloading: !model.downloads.isEmpty,
        isDownloadActive: $isDownloadActive,
        downloadSingleAction: {
          Task {
            isDownloadActive = true
            do {
              fileData = try await model.download(file: file)
            } catch {}
            isDownloadActive = false
          }
        },
        downloadWithUpdatesAction: {
          isDownloadActive = true
          downloadTask = Task {
            do {
              try await SuperStorageModel.$supportPartialDownloads.withValue(file.name.hasSuffix(".jpeg"), operation: {
                fileData = try await model.downloadWithProgress(file: file)
              })
            } catch {}
            isDownloadActive = false
          }
        },
        downloadMultipleAction: {
          isDownloadActive = true
          downloadTask = Task {
            do { fileData = try await model.multiDownloadWithProgress(file: file) }
            catch {}
            isDownloadActive = false
          }
        }
      )
      if !model.downloads.isEmpty {
        // Show progress for any ongoing downloads.
        Downloads(downloads: model.downloads)
      }

      if !duration.isEmpty {
        Text("Duration: \(duration)")
          .font(.caption)
      }

      if let fileData {
        // Show a preview of the file if it's a valid image.
        FilePreview(fileData: fileData)
      }
    }
    .animation(.easeOut(duration: 0.33), value: model.downloads)
    .listStyle(.insetGrouped)
    .toolbar {
      Button(action: {
        model.stopDownloads = true
        timerTask?.cancel()
      }, label: { Text("Cancel All") })
        .disabled(model.downloads.isEmpty)
    }
    .onDisappear {
      fileData = nil
      model.reset()
      downloadTask?.cancel()
    }
  }
}
