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

## 🛠 Installation

### Swift Package Manager

## 📦 Installation (Swift Package Manager)

1. Open **Xcode**
2. Navigate to **File → Add Packages…**
3. Enter the repository URL:

```text
https://github.com/Pharos-iOS-Team/PharosDownloadManager
```

4. Click **Add Package**

---

## 🚀 Usage

### 1. Setup

```swift
import PharosDownloadManager

let manager = PharosDownloadManager.shared
manager.enableLogging = true
manager.headers = ["Authorization": "Bearer <token>"]
```

### 2. Define a Downloadable Item

```swift
struct FileItem: Downloadable {
    let id: String
    let downloadURL: URL
}
```

### 3. Start a Download

```swift
let file = FileItem(id: "file1", downloadURL: URL(string: "https://example.com/file.zip")!)
manager.download(item: file)
```

### 4. Pause / Resume / Cancel

```swift
manager.pause(item: file)
manager.resume(item: file)
manager.cancel(id: file.id)
```

### 5. Observe Progress with Combine

```swift
import Combine

let cancellable = manager.progressPublisher(for: file.id)
    .sink { progress in
        print("Download progress: \(progress * 100)%")
    }
```

### 6. Handle Background Session in AppDelegate / SceneDelegate

```swift
func application(_ application: UIApplication,
                 handleEventsForBackgroundURLSession identifier: String,
                 completionHandler: @escaping () -> Void) {
    PharosDownloadManager.shared.handleBackgroundEvents(identifier: identifier, completionHandler: completionHandler)
}
```

### 7. Save State Before Force Quit

```swift
func applicationWillTerminate(_ application: UIApplication) {
    PharosDownloadManager.shared.saveStateBeforeTermination()
}
```

---

## 🔄 Download States

`DownloadState` enum provides the current state of a download:

```swift
public enum DownloadState: Equatable, Sendable {
    case idle
    case downloading(progress: Double)
    case paused(resumeData: Data?)
    case completed(localURL: URL)
    case failed(error: String)
}
```

---

## ⚙️ Customization

- **Global Headers**: `PharosDownloadManager.shared.headers`
- **Enable Logging**: `PharosDownloadManager.shared.enableLogging = true`
- **Resume Data Directory**: Default is app's `Caches` directory
- **Combine Publishers**: Observe individual download progress via `progressPublisher(for:)`

---

## 📌 Notes

- Downloads automatically resume if the app restarts and the user intended the download (`UserDefaults` tracks intent).
- Force-quits are handled by saving resume data before termination.
- Fully compatible with SwiftUI or UIKit.

---

## 📝 License

Copyright © 2025 Pharos Solutions GmbH. All rights reserved.
