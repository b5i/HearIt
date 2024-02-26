//
//  Line.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import SwiftUI

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var toReturn = Path()
        toReturn.addLines([.zero, CGPoint(x: rect.width, y: 0)])
        
        return toReturn
    }
}
