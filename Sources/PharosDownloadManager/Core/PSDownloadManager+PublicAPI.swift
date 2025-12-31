// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation
import Combine
import os

// MARK: - Control Logic & Lifecycle
extension PSDownloadManager {
  
  // MARK: - Auto Resume Logic
  
  /// Determines if a specific item should automatically resume downloading.
  /// This is typically called during app launch or list initialization. It returns `true` only if:
  /// 1. The user previously initiated the download (Intent is true).
  /// 2. Valid resume data exists on disk.
  public func shouldAutoResume(id: String) -> Bool {
    let userIntendsDownload = UserDefaults.standard.bool(forKey: "intent_\(id)")
    let hasResumeData = getSavedResumeData(for: id) != nil
    return userIntendsDownload && hasResumeData
  }
  
  // MARK: - Core Actions
  
  /// Primary entry point to start or resume a download.
  ///
  /// This method is "smart"—it checks the current state of the item before starting:
  /// 1. If paused in memory, it resumes immediately.
  /// 2. If valid resume data exists on disk, it restores the session from that point.
  /// 3. Otherwise, it starts a fresh download from scratch.
  ///
  /// It also sets the user intent to `true`, ensuring the download attempts to persist across sessions.
  public func download<T: Downloadable>(item: T) {
    setUserIntent(downloading: true, for: item.stringID)
    
    Task { @MainActor in
      // First check in-memory paused state
      if case .paused(let data) = downloadStates[item.stringID], let resumeData = data {
        log("⏯️ Resuming \(item.id) from memory")
        await startTask(with: resumeData, for: item)
      }
      // Then check on-disk resume data
      else if let diskResumeData = getSavedResumeData(for: item.stringID) {
        log("⏯️ Resuming \(item.id) from disk")
        await startTask(with: diskResumeData, for: item)
      }
      // Else start fresh
      else {
        log("🚀 Starting fresh \(item.id)")
        await startFreshTask(for: item)
      }
    }
  }
  
  /// Explicitly resumes a paused item.
  public func resume<T: Downloadable>(item: T) {
    setUserIntent(downloading: true, for: item.stringID)
    
    Task { @MainActor in
      if let state = downloadStates[item.stringID], case .paused(let data) = state, let resumeData = data {
        log("⏯️ Resuming \(item.id) from disk")
        await startTask(with: resumeData, for: item)
      } else {
        log("🚀 Starting fresh \(item.stringID)")
        download(item: item)
      }
    }
  }
  
  /// Pauses an active download.
  /// This cancels the underlying network task using `cancel(byProducingResumeData:)`.
  /// The generated resume data is saved to memory and disk, allowing the download to continue later
  /// without restarting.
  public func pause<T: Downloadable>(item: T) {
    Task { @MainActor in
      guard let task = await getTask(for: item.stringID) else { return }
      
      log("⏯️ Pausing \(item.id)")
      setUserIntent(downloading: false, for: item.stringID)
      
      task.cancel(byProducingResumeData: { [weak self] data in
        guard let self else { return }
        self.updateState(for: item.stringID, to: .paused(resumeData: data))
        if let data = data {
          self.saveResumeData(data, for: item.stringID)
        }
      })
      
      await tasksActor.remove(item.stringID)
      tryStartNextQueuedTask()
    }
  }
  
  /// Cancels an active or queued download permanently.
  /// Unlike `pause`, this discards any progress and deletes stored resume data. The state is reset to `.idle`.
  public func cancel(id: String) {
    Task { @MainActor in
      log("❌ Canceling \(id)")
      setUserIntent(downloading: false, for: id)
      
      if let task = await getTask(for: id) {
        task.cancel()
        await tasksActor.remove(id)
      }
      
      clearResumeData(for: id)
      updateState(for: id, to: .idle)
      tryStartNextQueuedTask()
    }
  }
  
  /// Completely removes a download artifact from the system.
  public func delete<T: Downloadable>(for item: T) {
    log("🗑️ Deleting \(item.id)")
    setUserIntent(downloading: false, for: item.stringID)
    
    cancel(id: item.stringID)
    
    let localURL = getLocalFileURL(for: item)
    if FileManager.default.fileExists(atPath: localURL.path) {
      try? FileManager.default.removeItem(at: localURL)
    }
    
    clearResumeData(for: item.stringID)
    updateState(for: item.stringID, to: .idle)
    tryStartNextQueuedTask()
  }
  
  // MARK: - System Hooks
  
  /// Captures the system completion handler for background URL sessions.
  /// **Usage:** Call this method in your `AppDelegate`'s `handleEventsForBackgroundURLSession`.
  public func handleBackgroundEvents(identifier: String, completionHandler: @escaping () -> Void) {
    self.backgroundCompletionHandler = completionHandler
  }
  
  /// Attempts to gracefully save resume data before the app terminates.
  /// This uses a synchronous semaphore to block the main thread for up to 2 seconds.
  /// This is necessary because `applicationWillTerminate` does not support asynchronous `Task` execution.
  public func saveStateBeforeTermination() {
    let semaphore = DispatchSemaphore(value: 0)
    
    session.getAllTasks { tasks in
      for task in tasks {
        if let downloadTask = task as? URLSessionDownloadTask,
           let id = task.taskDescription {
          
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
  
  /// Returns the precise local file URL for a download item.
  public func getLocalFileURL(for item: some Downloadable) -> URL {
    return self.downloadDirectory.appendingPathComponent(item.downloadURL.lastPathComponent)
  }
  
  // MARK: - Combine Publishers
  
  /// Returns a Combine publisher that emits progress values (0.0 - 1.0) for a specific download ID.
  public func progressPublisher(for id: String) -> AnyPublisher<Double, Never> {
    $downloadStates
      .compactMap { $0[id] }
      .map { state -> Double in
        if case .downloading(let progress) = state {
          return progress
        }
        return 0.0
      }
      .eraseToAnyPublisher()
  }
}
