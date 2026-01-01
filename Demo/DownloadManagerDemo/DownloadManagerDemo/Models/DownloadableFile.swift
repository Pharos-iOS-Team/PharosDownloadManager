// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation
import PharosDownloadManager

struct DownloadableFile: Downloadable {
  let id: String
  let downloadURL: URL
}

