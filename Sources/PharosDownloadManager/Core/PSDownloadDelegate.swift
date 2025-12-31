// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

/// A specialized delegate class responsible for handling lifecycle events from `URLSession`.
/// `PSDownloadDelegate` acts as the communication bridge between the system's background download process
/// and the `PSDownloadManager`. It translates raw byte streams and system events into high-level application states
public final class PSDownloadDelegate: NSObject, URLSessionDownloadDelegate {
  weak var manager: PSDownloadManager?
  
  public override init() {
    super.init()
  }
  
  // MARK: - Progress Updates
  /// Sent periodically to notify the delegate of download progress.
  public func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    guard let id = downloadTask.taskDescription else { return }
    
    // Calculate progress safely to avoid division by zero
    let progress = totalBytesExpectedToWrite > 0
    ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    : 0
    
    manager?.updateState(for: id, to: .downloading(progress: progress))
  }
  
  // MARK: - Download Completion
  /// Sent when a download task has finished downloading to a temporary location.
  /// This method is responsible for moving the file from the temp directory, to the persistent `downloadDirectory` defined in the manager.
  public func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    guard let manager, let id = downloadTask.taskDescription else { return }
    
    // 1. Update Intent: Mark that the user no longer actively expects this to be "in progress"
    manager.setUserIntent(downloading: false, for: id)
    
    // 2. Determine Destination
    let destinationURL = manager.downloadDirectory.appendingPathComponent(
      downloadTask.originalRequest?.url?.lastPathComponent ?? "\(id).file"
    )
    
    do {
      // 3. Cleanup existing files if overwrite is necessary
      if FileManager.default.fileExists(atPath: destinationURL.path) {
        try FileManager.default.removeItem(at: destinationURL)
      }
      
      // 4. Persist the file
      try FileManager.default.moveItem(at: location, to: destinationURL)
      manager.updateState(for: id, to: .completed(localURL: destinationURL))
      manager.clearResumeData(for: id)
    } catch {
      manager.updateState(for: id, to: .failed(error: error.localizedDescription))
    }
    
    // 5. Cleanup Task Actor & Queue
    Task { await manager.tasksActor.remove(id) }
    manager.tryStartNextQueuedTask()
  }
  
  // MARK: - Task Completion / Error Handling
  /// Sent when a task completes. This is called for both success and failure.
  public func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: Error?
  ) {
    guard let manager, let id = task.taskDescription else { return }
    
    if let error = error as NSError? {
      // Check if the error contains resume data (happens when a download is canceled to pause it)
      if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
        manager.saveResumeData(resumeData, for: id)
        manager.updateState(for: id, to: .paused(resumeData: resumeData))
      }
      // Ignore standard cancellation errors (user stopped it intentionally without pause), report others
      else if error.code != NSURLErrorCancelled {
        manager.setUserIntent(downloading: false, for: id)
        manager.updateState(for: id, to: .failed(error: error.localizedDescription))
      }
    }
    
    // Ensure the task is removed from the active list so new tasks can start
    Task { await manager.tasksActor.remove(id) }
    manager.tryStartNextQueuedTask()
  }
  
  // MARK: - Background Session Handling
  /// Called when all background events for the session are complete.
  /// This executes the system completion handler saved in `AppDelegate` or `SceneDelegate` to let the OS know it can suspend the app again.
  public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    DispatchQueue.main.async { [weak self] in
      self?.manager?.backgroundCompletionHandler?()
      self?.manager?.backgroundCompletionHandler = nil
    }
  }
}
