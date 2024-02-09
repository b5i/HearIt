//
//  AirPlayButton.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import SwiftUI
import AVKit

struct AirPlayButton: UIViewRepresentable {
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = UIColor.lightGray
        routePickerView.prioritizesVideoDevices = false

        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
    
    typealias UIViewType = AVRoutePickerView
}
