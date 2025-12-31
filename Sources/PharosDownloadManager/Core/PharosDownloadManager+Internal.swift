// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

internal extension PharosDownloadManager {
  // MARK: - Task Startup
  func startFreshTask(for item: some Downloadable) {
    var request = URLRequest(url: item.downloadURL)
    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    
    let task = session.downloadTask(with: request)
    task.taskDescription = item.id
    setTask(task, for: item.id)
    task.resume()
    updateState(for: item.id, to: .downloading(progress: 0.0))
  }
  
  func startTask(with resumeData: Data?, for item: some Downloadable) {
    guard let resumeData = resumeData else {
      startFreshTask(for: item)
      return
    }
    let task = session.downloadTask(withResumeData: resumeData)
    task.taskDescription = item.id
    setTask(task, for: item.id)
    task.resume()
    updateState(for: item.id, to: .downloading(progress: 0.0))
  }
  
  // MARK: - Thread Safety
  func setTask(_ task: URLSessionDownloadTask?, for id: String) {
    tasksQueue.async(flags: .barrier) { self.tasks[id] = task }
  }
  
  func getTask(for id: String) -> URLSessionDownloadTask? {
    return tasksQueue.sync { tasks[id] }
  }
  
  func updateState(for id: String, to state: DownloadState) {
    DispatchQueue.main.async { self.downloadStates[id] = state }
  }
  
  func reconnectBackgroundTasks() {
    session.getAllTasks { tasks in
      for task in tasks {
        if let id = task.taskDescription, let downloadTask = task as? URLSessionDownloadTask {
          self.setTask(downloadTask, for: id)
          if task.state == .running {
            self.updateState(for: id, to: .downloading(progress: 0.0))
          }
        }
      }
    }
  }
}
