//
//  AirPlayButton.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import SwiftUI
import AVKit

struct AirPlayButton: UIViewRepresentable {
    let color: UIColor
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = self.color
        routePickerView.activeTintColor = .systemGreen
        routePickerView.prioritizesVideoDevices = false

        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = self.color
    }
    
    typealias UIViewType = AVRoutePickerView
}
