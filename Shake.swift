//
//  Shake.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 12.02.2024.
//

import SwiftUI

// inspired from https://medium.com/devtechie/shake-animation-with-animatable-in-swiftui-17a91f694ce6
struct Shake: AnimatableModifier {
    var shakes: CGFloat = 0
    var direction: ShakeDirection = .horizontal
    
    var animatableData: CGFloat {
        get {
            shakes
        } set {
            shakes = newValue
        }
    }
    
    func body(content: Content) -> some View {
        switch self.direction {
        case .vertical:
            content
                .offset(y: sin(shakes * .pi * 2) * 5)
        case .horizontal:
            content
                .offset(x: sin(shakes * .pi * 2) * 5)
        case .diagonal:
            content
                .rotationEffect(.radians(sin(shakes * .pi * 2.0) * 0.15))
        }
    }
    
    enum ShakeDirection {
        case vertical
        case horizontal
        case diagonal
    }
}

extension View {
    func shake(with shakes: CGFloat, direction: Shake.ShakeDirection = .horizontal) -> some View {
        modifier(Shake(shakes: shakes, direction: direction))
    }
}

struct ShakeTestButton: View {
    @State private var shakeNumber: CGFloat = 0
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.red)
            .frame(width: 50, height: 50)
            .shake(with: shakeNumber, direction: .diagonal)
            .onTapGesture {
                withAnimation {
                    shakeNumber += 2
                }
            }
    }
}

#Preview {
    ShakeTestButton()
}
