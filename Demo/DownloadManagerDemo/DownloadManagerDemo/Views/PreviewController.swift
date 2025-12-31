// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import SwiftUI
import QuickLook

struct PreviewController: UIViewControllerRepresentable {
  let url: URL
  
  func makeUIViewController(context: Context) -> QLPreviewController {
    let controller = QLPreviewController()
    controller.dataSource = context.coordinator
    return controller
  }
  
  func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) { }
  
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  
  class Coordinator: NSObject, QLPreviewControllerDataSource {
    let parent: PreviewController
    init(_ parent: PreviewController) { self.parent = parent }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
      parent.url as QLPreviewItem
    }
  }
}

