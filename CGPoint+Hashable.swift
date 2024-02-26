//
//  CGPoint+Hashable.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 24.02.2024.
//

import Foundation
import CoreGraphics

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
}
