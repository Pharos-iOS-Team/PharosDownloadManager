// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

/// An Actor responsible for the thread-safe management of active and queued download tasks.
/// `PSDownloadTasksActor` serves as the "Source of Truth" for which tasks are currently executing
/// and which are waiting (queued). By using a Swift Actor, we eliminate race conditions when multiple threads
actor PSDownloadTasksActor {
  
  /// The maximum number of downloads allowed to execute at the same time.
  let maxConcurrentDownloads: Int
  
  /// A dictionary of tasks currently executing network requests.
  var runningTasks: [String: URLSessionDownloadTask] = [:]
  
  /// A dictionary of tasks that have been created but are paused waiting for a slot.
  var queuedTasks: [String: URLSessionDownloadTask] = [:]
  
  
  init(maxConcurrentDownloads: Int) {
    self.maxConcurrentDownloads = maxConcurrentDownloads
  }
  
  /// Registers a new task and determines if it can start immediately.
  /// This method checks the current count of `runningTasks`.
  /// - If `runningTasks < maxConcurrentDownloads`: The task is added to `runningTasks` and returns `true`.
  /// - Otherwise: The task is added to `queuedTasks` and returns `false`.
  func registerAndCanStart(_ task: URLSessionDownloadTask, id: String) -> Bool {
    if runningTasks.count < maxConcurrentDownloads {
      runningTasks[id] = task
      return true
    } else {
      queuedTasks[id] = task
      return false
    }
  }
  
  /// Updates or removes a task reference safely.
  /// This is often used when reconnecting to background sessions where tasks already exist, or when simply clearing a task reference.
  func set(_ task: URLSessionDownloadTask?, for id: String) {
    if let task = task {
      // If we are updating an existing task, we need to know which list it belongs to.
      if runningTasks[id] != nil {
        runningTasks[id] = task
      } else {
        queuedTasks[id] = task
      }
    } else {
      runningTasks[id] = nil
      queuedTasks[id] = nil
    }
  }
  
  /// Retrieves a task by ID from either the running or queued lists.
  func get(_ id: String) -> URLSessionDownloadTask? {
    runningTasks[id] ?? queuedTasks[id]
  }
  
  /// Completely removes a task from tracking (both running and queued).
  func remove(_ id: String) {
    runningTasks[id] = nil
    queuedTasks[id] = nil
  }
  
  /// Peeks at the next available task in the queue without modifying state.
  func nextQueuedTask() -> (id: String, task: URLSessionDownloadTask)? {
    queuedTasks.first.map { (key: $0.key, value: $0.value) }
  }
  
  /// Checks if a slot is available and moves the next task from 'queued' to 'running'.
  func promoteNextQueuedTaskIfAvailable() -> (id: String, task: URLSessionDownloadTask)? {
    guard runningTasks.count < maxConcurrentDownloads,
          let next = nextQueuedTask() else { return nil }
    
    //Remove from queue -> Add to running
    queuedTasks[next.id] = nil
    runningTasks[next.id] = next.task
    return next
  }
}
