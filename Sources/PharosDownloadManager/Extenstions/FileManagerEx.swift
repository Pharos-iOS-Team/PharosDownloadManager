// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

/// Extension to `FileManager` handling low-level file operations for the Download Manager.
extension FileManager {
  /// Persists the binary resume data to a file on disk.
  /// This creates a file named `{id}.resume` in the specified directory.
  func saveResumeData(_ data: Data, for id: String, in directory: URL) throws {
    let url = directory.appendingPathComponent("\(id).resume")
    try data.write(to: url)
  }
  
  /// Retrieves stored resume data from disk if it exists.
  /// Used to "rehydrate" a download task so it can continue from where it left off.
  func getSavedResumeData(for id: String, in directory: URL) -> Data? {
    let url = directory.appendingPathComponent("\(id).resume")
    return try? Data(contentsOf: url)
  }
  
  /// Deletes the resume data file from disk.
  ///
  /// This is critical for housekeeping. You should call this when:
  /// 1. A download completes successfully (data is no longer needed).
  /// 2. A user cancels a download (they don't want to resume it).
  func clearResumeData(for id: String, in directory: URL) throws {
    let url = directory.appendingPathComponent("\(id).resume")
    try self.removeItem(at: url)
  }
}
