// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "PharosDownloadManager",
  platforms: [
      .iOS(.v15),
      .macOS(.v12)
  ],
  products: [
    .library(
      name: "PharosDownloadManager",
      targets: ["PharosDownloadManager"]
    ),
  ],
  targets: [
    .target(
      name: "PharosDownloadManager"
    ),
    
  ]
)
