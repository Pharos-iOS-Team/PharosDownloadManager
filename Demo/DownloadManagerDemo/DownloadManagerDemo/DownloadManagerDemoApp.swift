// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import SwiftUI

@main
struct DownloadManagerDemoApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    WindowGroup {
      DownloadsListView()
    }
  }
}
