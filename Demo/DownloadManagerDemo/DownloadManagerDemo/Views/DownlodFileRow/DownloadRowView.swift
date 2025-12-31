// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import SwiftUI
import QuickLook
import PharosDownloadManager

struct DownloadRowView: View {
  @ObservedObject var viewModel: DownloadFileViewModel
  @State private var showingPreview = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(viewModel.file.id)
          .font(.headline)
        Spacer()
        
        if case let .completed(localURL) = viewModel.state {
          Button("Preview") {
            showingPreview = true
          }
          .sheet(isPresented: $showingPreview) {
            PreviewController(url: localURL)
          }
          .buttonStyle(.borderedProminent)
        }
      }
      
      // Switch on download state
      switch viewModel.state {
      case .idle:
        Button("Start Download") {
          viewModel.download()
        }
        .buttonStyle(.bordered)
        
      case .queued:
        Text("Queued...")
          .foregroundColor(.gray)
        
      case .downloading:
        HStack {
          VStack(alignment: .leading) {
            ProgressView(value: min(max(viewModel.progress, 0), 1))
            Text("\(Int(min(max(viewModel.progress, 0), 1) * 100))%")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.top, 20)
          Spacer()
          Button(action: { viewModel.cancel() }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.red)
          }
          .buttonStyle(BorderlessButtonStyle())
          Button(action: { viewModel.pause() }) {
            Image(systemName: "pause.circle.fill")
              .foregroundColor(.yellow)
          }
          .buttonStyle(BorderlessButtonStyle())
        }
        
      case .paused:
        HStack {
          Text("⏸ Paused")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
          Button(action: { viewModel.resume() }) {
            Image(systemName: "play.circle.fill")
              .foregroundColor(.green)
          }
          .buttonStyle(BorderlessButtonStyle())
          Button(action: { viewModel.cancel() }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.red)
          }
          .buttonStyle(BorderlessButtonStyle())
        }
        
      case let .completed(localURL):
        HStack {
          VStack(alignment: .leading) {
            Text("✅ Downloaded")
              .foregroundColor(.green)
            Text(localURL.lastPathComponent)
              .font(.caption2)
              .foregroundColor(.gray)
          }
          .padding(.top, 10)
          Spacer()
          Button(action: { viewModel.delete() }) {
            Image(systemName: "trash")
              .foregroundColor(.red)
          }
          .buttonStyle(BorderlessButtonStyle())
        }
        
      case .failed:
        HStack {
          Text("❌ Failed")
            .foregroundColor(.red)
          Spacer()
          Button("Retry") { viewModel.download() }
            .buttonStyle(.bordered)
        }
      }
    }
    .padding(.vertical, 8)
  }
}
