// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

// MARK: - Persistence & Helper Methods
extension PSDownloadManager {
  
  // MARK: - User Intent
  
  /// Records the user’s specific intent to download or cancel an item.
  /// **Why is this needed?**
  /// The state of a `URLSessionTask` is transient. If the app crashes or terminates, we lose track of
  /// whether a task was paused intentionally by the user or if it was just waiting in the queue.
  /// Upon app relaunch, the manager checks this intent flag to decide whether to automatically resume a task.
  func setUserIntent(downloading: Bool, for id: String) {
    if downloading {
      UserDefaults.standard.set(true, forKey: "intent_\(id)")
    } else {
      UserDefaults.standard.removeObject(forKey: "intent_\(id)")
    }
  }
  
  // MARK: - Resume Data Helpers
  
  /// Persists the partial download data  to disk.
  /// When a download is paused or fails, `URLSession` provides a `Data` object containing the bytes downloaded so far.
  /// This method delegates to `FileManager` to save that data to the `resumeDataDirectory`.
  func saveResumeData(_ data: Data, for id: String) {
    try? FileManager.default.saveResumeData(data, for: id, in: self.resumeDataDirectory)
  }
  
  /// Retrieves previously saved resume data from disk.
  func getSavedResumeData(for id: String) -> Data? {
    FileManager.default.getSavedResumeData(for: id, in: self.resumeDataDirectory)
  }
  
  /// Deletes the saved resume data from disk.
  /// This should be called when:
  /// 1. A download completes successfully.
  /// 2. A download is explicitly cancelled by the user.
  func clearResumeData(for id: String) {
    try? FileManager.default.clearResumeData(for: id, in: self.resumeDataDirectory)
  }
}
