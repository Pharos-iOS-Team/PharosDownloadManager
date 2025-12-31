// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation
import Combine

extension PharosDownloadManager {
  // MARK: - Public Control API
  public func shouldAutoResume(id: String) -> Bool {
    let userIntendsDownload = UserDefaults.standard.bool(forKey: "intent_\(id)")
    let hasResumeData = getSavedResumeData(for: id) != nil
    return userIntendsDownload && hasResumeData
  }
  
  public func download(item: some Downloadable) {
    setUserIntent(downloading: true, for: item.id)
    
    if case .paused(let data) = downloadStates[item.id], let resumeData = data {
      log("⏯️ Resuming \(item.id) from memory")
      startTask(with: resumeData, for: item)
    } else if let diskResumeData = getSavedResumeData(for: item.id) {
      log("⏯️ Resuming \(item.id) from disk")
      startTask(with: diskResumeData, for: item)
    } else {
      log("🚀 Starting fresh \(item.id)")
      startFreshTask(for: item)
    }
  }
  
  public func resume(item: some Downloadable) {
    setUserIntent(downloading: true, for: item.id)
    if let state = downloadStates[item.id], case .paused(let data) = state {
      log("⏯️ Resuming \(item.id) from disk")
      startTask(with: data, for: item)
    } else {
      log("🚀 Starting fresh \(item.id)")
      download(item: item)
    }
  }
  
  public func pause(item: some Downloadable) {
    guard let task = getTask(for: item.id) else { return }
    log("⏯️ Pausing \(item.id)")
    
    setUserIntent(downloading: false, for: item.id)
    
    task.cancel(byProducingResumeData: { [weak self] data in
      guard let self = self else { return }
      self.updateState(for: item.id, to: .paused(resumeData: data))
      if let data = data { self.saveResumeData(data, for: item.id) }
    })
    setTask(nil, for: item.id)
  }
  
  public func cancel(id: String) {
    log("❌ Canceling \(id)")
    setUserIntent(downloading: false, for: id)
    
    getTask(for: id)?.cancel()
    setTask(nil, for: id)
    clearResumeData(for: id)
    updateState(for: id, to: .idle)
  }
  
  public func delete(for item: some Downloadable) {
    log("🗑️ Deleting \(item.id)")
    setUserIntent(downloading: false, for: item.id)
    cancel(id: item.id)
    
    if let localURL = getLocalFileURL(for: item), FileManager.default.fileExists(atPath: localURL.path) {
      try? FileManager.default.removeItem(at: localURL)
    }
    
    clearResumeData(for: item.id)
    updateState(for: item.id, to: .idle)
  }
  
  // MARK: - System Hooks
  public func handleBackgroundEvents(identifier: String, completionHandler: @escaping () -> Void) {
    self.backgroundCompletionHandler = completionHandler
  }
  
  public func saveStateBeforeTermination() {
    let semaphore = DispatchSemaphore(value: 0)
    session.getAllTasks { tasks in
      for task in tasks {
        if let downloadTask = task as? URLSessionDownloadTask, let id = task.taskDescription {
          downloadTask.cancel(byProducingResumeData: { [weak self] data in
            if let self = self, let data = data {
              self.saveResumeData(data, for: id)
              self.updateState(for: id, to: .paused(resumeData: data))
              self.log("💾 Saved resume data for \(id) during force quit")
            }
            semaphore.signal()
          })
        } else {
          semaphore.signal()
        }
      }
    }
    _ = semaphore.wait(timeout: .now() + 2.0)
  }
  
  // MARK: - Publishers
  public func progressPublisher(for id: String) -> AnyPublisher<Double, Never> {
    $downloadStates
      .compactMap { $0[id] }
      .map { state -> Double in
        if case .downloading(let progress) = state { return progress }
        return 0.0
      }
      .eraseToAnyPublisher()
  }
}
