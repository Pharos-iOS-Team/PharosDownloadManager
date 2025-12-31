// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

/// Represents the current state of a download.
public enum DownloadState: Equatable, Sendable {
  case idle
  case queued
  case downloading(progress: Double)
  case paused(resumeData: Data?)
  case completed(localURL: URL)
  case failed(error: String)
}
