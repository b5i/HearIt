//
//  BlurView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 24.02.2024.
//

import Foundation
import SwiftUI

struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        return blurEffectView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
