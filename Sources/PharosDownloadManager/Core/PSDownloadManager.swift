// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation
import Combine
import os

/// `PSDownloadManager` acts as the central hub for handling file downloads. It integrates with `URLSession`'s background configuration,
/// allowing downloads to continue even when the app is suspended.
public final class PSDownloadManager: ObservableObject, @unchecked Sendable {
  public static let `default` = PSDownloadManager()
  
  /// A dictionary mapping unique download identifiers (String IDs) to their current state.
  @Published public var downloadStates: [String: DownloadState] = [:]
  
  /// Custom HTTP headers to be applied to every new download request.
  var headers: [String: String]
  
  /// Toggles the internal logger.
  var enableLogging: Bool
  
  /// The directory on the file system where completed downloads will be moved.
  let downloadDirectory: URL
  
  /// Internal actor responsible for thread-safe tracking of active and queued tasks.
  let tasksActor: PSDownloadTasksActor
  
  /// The underlying URLSession used for download tasks.
  var session: URLSession!
  
  /// Closure captured from `AppDelegate` or `SceneDelegate` to handle background session completion events.
  var backgroundCompletionHandler: (() -> Void)?
  
  /// The directory used to store resume data (blobs) for paused downloads.
  let resumeDataDirectory =
  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
  
  private let logger =
  Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.yourapp", category: "PSDownloadManager")
  
  private let delegate = PSDownloadDelegate()
  
  /// Initializes a new instance of the Download Manager.
  public init(
    maxConcurrentDownloads: Int = 3,
    downloadDirectory: URL =
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
    headers: [String: String] = [:],
    enableLogging: Bool = true,
    configuration: URLSessionConfiguration = {
      let config = URLSessionConfiguration.background(
        withIdentifier: "com.pharos.backgroundDownload"
      )
      config.isDiscretionary = false
      config.sessionSendsLaunchEvents = true
      return config
    }()
  ) {
    self.tasksActor = PSDownloadTasksActor(maxConcurrentDownloads: maxConcurrentDownloads)
    self.downloadDirectory = downloadDirectory
    self.headers = headers
    self.enableLogging = enableLogging
    self.session = URLSession(configuration: configuration,
                              delegate: delegate,
                              delegateQueue: nil)
    delegate.manager = self
    reconnectBackgroundTasks()
  }
  
  /// Logs a message to the OS console if logging is enabled.
  func log(_ message: String, type: OSLogType = .debug) {
    guard enableLogging else { return }
    logger.log(level: type, "\(message, privacy: .public)")
  }
  
  /// Updates the observable state for a specific download ID.
  func updateState(for id: String, to state: DownloadState) {
    DispatchQueue.main.async {
      self.downloadStates[id] = state
    }
  }
}

// MARK: - Task Management
extension PSDownloadManager {
  
  /// Checks the queue and starts the next available task if the concurrency limit permits.
  /// This is typically called after a download completes or is canceled to keep the queue moving.
  func tryStartNextQueuedTask() {
    Task { @MainActor in
      while let next = await tasksActor.promoteNextQueuedTaskIfAvailable() {
        let id = next.id
        let task = next.task
        updateState(for: id, to: .downloading(progress: 0))
        task.resume()
        log("▶️ Started queued task \(id)")
      }
    }
  }
  
  /// Initiates a brand new download task from a `Downloadable` item.
  /// If the concurrency limit is reached, the task is created but immediately paused (queued).
  func startFreshTask<T: Downloadable>(for item: T) {
    Task { @MainActor in
      var request = URLRequest(url: item.downloadURL)
      headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
      
      let task = session.downloadTask(with: request)
      task.taskDescription = item.stringID
      
      let canStart = await tasksActor.registerAndCanStart(task, id: item.stringID)
      if canStart {
        updateState(for: item.stringID, to: .downloading(progress: 0))
        task.resume()
      } else {
        updateState(for: item.stringID, to: .queued)
      }
    }
  }
  
  /// Resumes a previously paused download using saved `resumeData`.
  func startTask<T: Downloadable>(with resumeData: Data, for item: T) {
    Task { @MainActor in
      let task = session.downloadTask(withResumeData: resumeData)
      task.taskDescription = item.stringID
      
      let canStart = await tasksActor.registerAndCanStart(task, id: item.stringID)
      if canStart {
        updateState(for: item.stringID, to: .downloading(progress: 0))
        task.resume()
      } else {
        updateState(for: item.stringID, to: .queued)
      }
    }
  }
  
  /// Retrieves a specific `URLSessionDownloadTask` from the actor by ID.
  func getTask(for id: String) async -> URLSessionDownloadTask? {
    await tasksActor.get(id)
  }
  
  /// Re-attaches to existing background tasks created in previous app sessions.
  /// This is called automatically on `init` to ensure that if the app was terminated while downloading, the manager regains control of those tasks upon relaunch.
  func reconnectBackgroundTasks() {
    session.getAllTasks { [weak self] tasks in
      guard let self else { return }
      
      Task {
        for task in tasks {
          guard
            let id = task.taskDescription,
            let downloadTask = task as? URLSessionDownloadTask
          else { continue }
          
          await self.tasksActor.set(downloadTask, for: id)
          
          if task.state == .running {
            self.updateState(for: id, to: .downloading(progress: 0))
          }
        }
      }
    }
  }
}
