// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

internal extension PharosDownloadManager {  
  // MARK: - User Intent
  func setUserIntent(downloading: Bool, for id: String) {
    if downloading {
      UserDefaults.standard.set(true, forKey: "intent_\(id)")
    } else {
      UserDefaults.standard.removeObject(forKey: "intent_\(id)")
    }
  }
  
  // MARK: - File & Resume Data
  func saveResumeData(_ data: Data, for id: String) {
    let url = resumeDataDirectory.appendingPathComponent("\(id).resume")
    try? data.write(to: url)
  }
  
  func getSavedResumeData(for id: String) -> Data? {
    let url = resumeDataDirectory.appendingPathComponent("\(id).resume")
    return try? Data(contentsOf: url)
  }
  
  func clearResumeData(for id: String) {
    let url = resumeDataDirectory.appendingPathComponent("\(id).resume")
    try? FileManager.default.removeItem(at: url)
  }
  
  func getLocalFileURL(for item: some Downloadable) -> URL? {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    let fileName = item.downloadURL.lastPathComponent
    return documentsURL?.appendingPathComponent(fileName)
  }
}
