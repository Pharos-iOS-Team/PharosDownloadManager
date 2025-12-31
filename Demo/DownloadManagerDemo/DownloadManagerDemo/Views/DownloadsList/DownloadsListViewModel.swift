// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation
import Combine
import PharosDownloadManager

final class DownloadsListViewModel: ObservableObject {
  @Published var files: [DownloadFileViewModel] = demoFiles.map { DownloadFileViewModel(file: $0) }
  
  static let demoFiles: [DownloadableFile] = [
    DownloadableFile(
      id: "Sample PDF",
      downloadURL: URL(string: "https://pdfobject.com/pdf/sample.pdf")!
    ),
    
    DownloadableFile(
      id: "Sample Text",
      downloadURL: URL(string: "https://www.w3.org/TR/PNG/iso_8859-1.txt")!
    ),
    
    DownloadableFile(
      id: "Sample Image",
      downloadURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png")!
    ),
    
    DownloadableFile(
      id: "Sample video",
      downloadURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!
    ),
    
    DownloadableFile(
      id: "Sample video (Large size)",
      downloadURL: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4")!
    ),
  ]
}
