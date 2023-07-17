

import Foundation

/// The download model.
class SuperStorageModel: ObservableObject {
  /// The list of currently running downloads.
  @Published var downloads: [DownloadInfo] = []
  @TaskLocal static var supportPartialDownloads = false
  func availableFiles() async throws -> [DownloadFile] {
    guard let url = URL(string: "http://localhost:8080/files/list") else {
      throw "Could not create the URL."
    }
    let (data, response) = try await
      URLSession.shared.data(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw "The server responded with an error."
    }

    guard let list = try? JSONDecoder()
      .decode([DownloadFile].self, from: data)
    else {
      throw "The server response was not recognized."
    }
    return list
  }

  func status() async throws -> String {
    guard let url = URL(string: "http://localhost:8080/files/status") else {
      throw "Could not create the URL."
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw "The server responded with an error."
    }
    return String(decoding: data, as: UTF8.self)
  }

  /// Downloads a file and returns its content.
  func download(file: DownloadFile) async throws -> Data {
    guard let url = URL(string: "http://localhost:8080/files/download?\(file.name)") else {
      throw "Could not create the URL."
    }
    await addDownload(name: file.name)
    let (data, response) = try await URLSession.shared.data(from: url)
    await updateDownload(name: file.name, progress: 1.0)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw "The server responded with an error."
    }
    return data
  }

  /// Downloads a file, returns its data, and updates the download progress in ``downloads``.
  func downloadWithProgress(file: DownloadFile) async throws -> Data {
    return try await downloadWithProgress(fileName: file.name, name: file.name, size: file.size)
  }

  /// Downloads a file, returns its data, and updates the download progress in ``downloads``.
  private func downloadWithProgress(fileName: String, name: String, size: Int, offset: Int? = nil) async throws -> Data {
    guard let url = URL(string: "http://localhost:8080/files/download?\(fileName)") else {
      throw "Could not create the URL."
    }
    await addDownload(name: name)
    let result: (downloadStream: URLSession.AsyncBytes, response: URLResponse)
    if let offset = offset {
      let urlRequest = URLRequest(url: url, offset: offset, length: size)
      result = try await URLSession.shared.bytes(for: urlRequest)
      guard (result.response as? HTTPURLResponse)?.statusCode == 206 else { throw "The server responded an error" }
    } else {
      result = try await URLSession.shared.bytes(from: url)
      guard (result.response as? HTTPURLResponse)?.statusCode == 200 else { throw "The server responded an error" }
    }
    var asyncDownloadIterator = result.downloadStream.makeAsyncIterator()
    var accumulator = ByteAccumulator(name: name, size: size)
    while await !stopDownloads, !accumulator.checkCompleted() {
      while !accumulator.isBatchCompleted,
            let byte = try await asyncDownloadIterator.next()
      {
        accumulator.append(byte)
      }
      let progress = accumulator.progress
      Task.detached(priority: .medium) {
        await self
          .updateDownload(name: name, progress: progress)
      }
      print(accumulator.description)
    }
    if await stopDownloads, !Self.supportPartialDownloads {
      throw CancellationError()
    }
    return accumulator.data
  }

  /// Downloads a file using multiple concurrent connections, returns the final content, and updates the download progress.
  func multiDownloadWithProgress(file: DownloadFile) async throws -> Data {
    func partInfo(index: Int, of count: Int) -> (offset: Int, size: Int, name: String) {
      let standardPartSize = Int((Double(file.size) / Double(count)).rounded(.up))
      let partOffset = index * standardPartSize
      let partSize = min(standardPartSize, file.size - partOffset)
      let partName = "\(file.name) (part \(index + 1))"
      return (offset: partOffset, size: partSize, name: partName)
    }
    let total = 4
    let parts = (0 ..< total).map { partInfo(index: $0, of: total) }
    // Add challenge code here.
    async let part1 = try downloadWithProgress(fileName: file.name, name: parts[0].name, size: parts[0].size, offset: parts[0].offset)
    async let part2 = try downloadWithProgress(fileName: file.name, name: parts[1].name, size: parts[1].size, offset: parts[1].offset)
    async let part3 = try downloadWithProgress(fileName: file.name, name: parts[2].name, size: parts[2].size, offset: parts[2].offset)
    async let part4 = try downloadWithProgress(fileName: file.name, name: parts[3].name, size: parts[3].size, offset: parts[3].offset)
    return try await [part1, part2, part3, part4]
      .reduce(Data(), +)
  }

  /// Flag that stops ongoing downloads.
  @MainActor var stopDownloads = false

  @MainActor func reset() {
    stopDownloads = false
    downloads.removeAll()
  }
}

extension SuperStorageModel {
  /// Adds a new download.
  @MainActor func addDownload(name: String) {
    let downloadInfo = DownloadInfo(id: UUID(), name: name, progress: 0.0)
    downloads.append(downloadInfo)
  }

  /// Updates a the progress of a given download.
  @MainActor func updateDownload(name: String, progress: Double) {
    if let index = downloads.firstIndex(where: { $0.name == name }) {
      var info = downloads[index]
      info.progress = progress
      downloads[index] = info
    }
  }
}
