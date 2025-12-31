// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation
import Combine

// MARK: - Download Manager
public final class PharosDownloadManager: NSObject, ObservableObject, @unchecked Sendable {
  public static let shared = PharosDownloadManager()
  
  // MARK: - Published State
  @Published public var downloadStates: [String: DownloadState] = [:]
  
  // MARK: - Public Configuration
  public var headers = [String: String]()
  public var enableLogging = true
  
  // MARK: - Internal Properties
  internal var session: URLSession!
  internal var backgroundCompletionHandler: (() -> Void)?
  
  // Thread-safe tasks
  internal var tasks: [String: URLSessionDownloadTask] = [:]
  internal let tasksQueue = DispatchQueue(label: Constants.queueLabel, attributes: .concurrent)
  
  // Persistence
  internal let resumeDataDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
  
  private override init() {
    super.init()
    let config = URLSessionConfiguration.background(withIdentifier: Constants.backgroundId)
    config.isDiscretionary = false
    config.sessionSendsLaunchEvents = true
    self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    reconnectBackgroundTasks()
  }
  
  // MARK: - Logging Helper
  internal func log(_ message: String) {
    if enableLogging { print("PharosDownloadManager: \(message)") }
  }
}
