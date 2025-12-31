// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation
import Combine
import PharosDownloadManager

final class DownloadFileViewModel: ObservableObject, Identifiable {
  
  let file: DownloadableFile
  @Published var progress: Double = 0.0
  @Published var state: DownloadState = .idle
  
  private var cancellables = Set<AnyCancellable>()
  
  init(file: DownloadableFile) {
    self.file = file
    
    // Check if the file already exists locally
    if let localURL = localFileURL(), FileManager.default.fileExists(atPath: localURL.path) {
      state = .completed(localURL: localURL)
      print("✅ File \(file.id) already downloaded at \(localURL.path)")
    } else if PSDownloadManager.default.shouldAutoResume(id: file.id) {
      print("🔄 Auto-resuming \(file.id) due to previous intent")
      Task { await PSDownloadManager.default.download(item: file) }
    }
    
    // Subscribe to progress updates
    PSDownloadManager.default.progressPublisher(for: file.id)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] value in self?.progress = value }
      .store(in: &cancellables)
    
    // Subscribe to download state updates
    PSDownloadManager.default.$downloadStates
      .compactMap { $0[file.id] }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] value in self?.state = value }
      .store(in: &cancellables)
  }
  
  // MARK: - Helpers
  private func localFileURL() -> URL? {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    let fileName = file.downloadURL.lastPathComponent
    return documentsURL?.appendingPathComponent(fileName)
  }
  
  // MARK: - Actions
  func download() {
    Task { await PSDownloadManager.default.download(item: file) }
  }
  
  func pause() {
    Task { await PSDownloadManager.default.pause(item: file) }
  }
  
  func resume() {
    Task { await PSDownloadManager.default.resume(item: file) }
  }
  
  func cancel() {
    Task { await PSDownloadManager.default.cancel(id: file.id) }
  }
  
  func delete() {
    Task { await PSDownloadManager.default.delete(for: file) }
    state = .idle
  }
}
