// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

extension PharosDownloadManager: URLSessionDownloadDelegate {
  
  public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                         didWriteData bytesWritten: Int64,
                         totalBytesWritten: Int64,
                         totalBytesExpectedToWrite: Int64) {
    guard let id = downloadTask.taskDescription else { return }
    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    updateState(for: id, to: .downloading(progress: progress))
  }
  
  public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                         didFinishDownloadingTo location: URL) {
    guard let id = downloadTask.taskDescription else { return }
    
    setUserIntent(downloading: false, for: id)
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let destinationURL = documentsURL.appendingPathComponent(downloadTask.originalRequest?.url?.lastPathComponent ?? "\(id).file")
    
    do {
      try? FileManager.default.removeItem(at: destinationURL)
      try FileManager.default.moveItem(at: location, to: destinationURL)
      updateState(for: id, to: .completed(localURL: destinationURL))
      clearResumeData(for: id)
    } catch {
      updateState(for: id, to: .failed(error: error.localizedDescription))
    }
    setTask(nil, for: id)
  }
  
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let id = task.taskDescription else { return }
    
    if let error = error as NSError? {
      if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
        saveResumeData(resumeData, for: id)
        updateState(for: id, to: .paused(resumeData: resumeData))
      } else if error.code != NSURLErrorCancelled {
        setUserIntent(downloading: false, for: id)
        updateState(for: id, to: .failed(error: error.localizedDescription))
      }
    }
    setTask(nil, for: id)
  }
  
  public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    DispatchQueue.main.async {
      self.backgroundCompletionHandler?()
      self.backgroundCompletionHandler = nil
    }
  }
}
