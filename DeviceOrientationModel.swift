//
//  DeviceOrientationModel.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 14.02.2024.
//

import Foundation
import UIKit

class DeviceOrientationModel: ObservableObject {
    static let shared = DeviceOrientationModel()
    
    var orientation: UIDeviceOrientation
    
    init () {
        orientation = UIDevice.current.orientation
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main, using: { _ in
            self.orientation = UIDevice.current.orientation
            self.update()
        })
    }
    
    func update() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
