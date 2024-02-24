//
//  CGSize+Hashable.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 24.02.2024.
//

import Foundation
import CoreGraphics

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
}
