// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import UIKit
import PharosDownloadManager

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   handleEventsForBackgroundURLSession identifier: String,
                   completionHandler: @escaping () -> Void) {
    print("⚡️ Background session finished events: \(identifier)")
    PSDownloadManager.default.handleBackgroundEvents(identifier: identifier,
                                                        completionHandler: completionHandler)
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    print("💀 App terminating. Performing panic save...")
    PSDownloadManager.default.saveStateBeforeTermination()
  }
}
