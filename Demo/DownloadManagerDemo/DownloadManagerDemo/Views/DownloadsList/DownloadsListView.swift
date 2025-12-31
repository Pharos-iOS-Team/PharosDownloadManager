// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import SwiftUI
import QuickLook

struct DownloadsListView: View {
  @StateObject private var viewModel = DownloadsListViewModel()
  
  var body: some View {
    NavigationView {
      VStack(spacing: 5) {
        Text("Pharos Download Manager Demo")
          .font(.largeTitle)
          .bold()
          .padding(.top)
        
        List {
          ForEach(viewModel.files) { file in
            DownloadRowView(viewModel: file)
          }
        }
      }
      .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
  }
}

