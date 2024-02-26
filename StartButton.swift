//
//  StartButton.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 25.02.2024.
//

import Foundation
import SwiftUI

struct StartButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var mode: Mode = .automatic
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            let mainColor: Color = {
                switch mode {
                case .automatic:
                    return colorScheme.textColor
                case .black:
                    return .white
                case .white:
                    return .black
                }
            }()
            let backgroundColor: Color = {
                switch mode {
                case .automatic:
                    return colorScheme.backgroundColor
                case .black:
                    return .black
                case .white:
                    return .white
                }
            }()
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(mainColor, style: StrokeStyle(lineWidth: 3))
                    .foregroundStyle(backgroundColor)
                Text("Start")
                    .foregroundStyle(mainColor)
                    .bold()
            }
        }
        .padding()
        .frame(width: 200, height: 100)
    }
    
    enum Mode {
        case automatic
        case black
        case white
    }
}
