# PharosDownloadManager

**PharosDownloadManager** is a robust Swift package for handling background downloads in iOS. It supports resumable downloads, pause/resume, progress tracking via Combine, and automatic recovery after app restarts or force-quits. Designed with simplicity and modern Swift paradigms, it works seamlessly with SwiftUI or UIKit.

---

## 📦 Features

- ✅ Background downloads with automatic resumption
- ✅ Pause, resume, cancel, and delete downloads
- ✅ Combine-based progress publishers
- ✅ Persistent resume data for force-quits and app restarts
- ✅ Global headers support for all downloads
- ✅ Debug logging toggle
- ✅ Fully `ObservableObject` compatible for SwiftUI

---

## 🛠 Installation (Swift Package Manager)

1. Open **Xcode**
2. Navigate to **File → Add Packages…**
3. Enter the repository URL:

```text
https://github.com/Pharos-iOS-Team/PharosDownloadManager
```

4. Click **Add Package**

---

## 🚀 Usage

### 1. Import the Package

```swift
import PharosDownloadManager
```

---

### 2. Initialize the Manager

**Default PSDownloadManager**

```swift
let manager = PSDownloadManager.default
```

**Custom PSDownloadManager**

```swift
let config = URLSessionConfiguration.background(withIdentifier: "com.myapp.customBackground")
config.isDiscretionary = false
config.sessionSendsLaunchEvents = true

let manager = PSDownloadManager(
    maxConcurrentDownloads: 2,
    downloadDirectory: customFolder,
    headers: ["Authorization": "Bearer <token>"],
    enableLogging = false,
    configuration: config
)
```

---

### 3. Define a Downloadable Item

```swift
struct FileItem: Downloadable {
    let id: String
    let downloadURL: URL
}
```

---

### 4. Start a Download

```swift
let file = FileItem(id: "file1", downloadURL: URL(string: "https://example.com/file.zip")!)
manager.download(item: file)
```

---

### 5. Pause / Resume / Cancel / Delete

```swift
manager.pause(item: file)
manager.resume(item: file)
manager.cancel(id: file.id)
manager.delete(for: file)
```

---

### 6. Observe Progress with Combine

```swift
import Combine

let cancellable = manager.progressPublisher(for: file.id)
    .sink { progress in
        print("Download progress: \(progress * 100)%")
    }
```

---

### 7. Handle Background Session in AppDelegate / SceneDelegate

```swift
func application(_ application: UIApplication,
                 handleEventsForBackgroundURLSession identifier: String,
                 completionHandler: @escaping () -> Void) {
    PSDownloadManager.default.handleBackgroundEvents(identifier: identifier,
                                                     completionHandler: completionHandler)
}
```

---

### 8. Save State Before Force Quit

```swift
func applicationWillTerminate(_ application: UIApplication) {
    PSDownloadManager.default.saveStateBeforeTermination()
}
```

---

## 🔄 Download States

`DownloadState` enum provides the current state of a download:

```swift
public enum DownloadState: Equatable, Sendable {
    case idle
    case queued
    case downloading(progress: Double)
    case paused(resumeData: Data?)
    case completed(localURL: URL)
    case failed(error: String)
}
```

---

## ⚙ Customization

- **Global Headers**: `PSDownloadManager.default.headers`
- **Enable Logging**: `PSDownloadManager.default.enableLogging = true`
- **Resume Data Directory**: Defaults to app's `Caches` folder
- **Combine Publishers**: Observe individual download progress via `progressPublisher(for:)`
- **Custom Download Directory, maxConcurrentDownloads, headers, enabling logs & URLSession Config**: You can initialize a separate manager with your own customization as needed (see usage example above).

---

## 📌 Notes

- Downloads automatically resume if the app restarts and the user intended the download (`UserDefaults` tracks intent).
- Force-quits are handled by saving resume data before termination.
- Fully compatible with SwiftUI or UIKit.

---

## 📝 License

Copyright © 2025 Pharos Solutions GmbH. All rights reserved.
