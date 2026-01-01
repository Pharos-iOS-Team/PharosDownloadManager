// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

/// Protocol defining the minimal requirements for a downloadable item.
public protocol Downloadable: Identifiable, Codable, Sendable {
  var id: String { get }
  var downloadURL: URL { get }
}
