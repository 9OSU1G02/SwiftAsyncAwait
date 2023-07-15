

import SwiftUI
import UIKit

/// The file download view.
struct DownloadView: View {
  /// The selected file.
  let file: DownloadFile
  @EnvironmentObject var model: SuperStorageModel
  /// The downloaded data.
  @State var fileData: Data?
  /// Should display a download activity indicator.
  @State var isDownloadActive = false

  @State var duration = ""

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
          // Download a file with UI progress updates.
        },
        downloadMultipleAction: {
          // Download a file in multiple concurrent parts.
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
      Button(action: {}, label: { Text("Cancel All") })
        .disabled(model.downloads.isEmpty)
    }
    .onDisappear {
      fileData = nil
      model.reset()
    }
  }
}
