// Copyright © 2025 Pharos Solutions GmbH. All rights reserved.

import Foundation

/// Protocol defining the minimal requirements for a downloadable item.
public protocol Downloadable: Codable, Sendable {
  associatedtype ID: Hashable
  
  var id: ID { get }
  var downloadURL: URL { get }
}

/// Helper to ensure a consistent string key for URLSession taskDescription
extension Downloadable {
  var stringID: String { "\(id)" }
}
