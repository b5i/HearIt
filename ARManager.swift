//
//  ARManager.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 14.02.2024.
//

import Foundation
import CoreGraphics
import ARKit

class ARManager: ObservableObject {
    static let isAREnabled = ARConfiguration.isSupported
    
    static let shared = ARManager()
    
    private var MM: MusiciansManager?
    
    private var PM: PlaybackManager?
    
    private(set) var isAROn: Bool = false
    
    private(set) var isLoading: Bool = false
    
    func setup(MM: MusiciansManager, PM: PlaybackManager) {
        self.MM = MM
        self.PM = PM
    }
    
    func reset() {
        self.setARMode(isOn: false)
        self.MM = nil
        self.PM = nil
        self.update()
    }
    
    func setARMode(isOn newStatus: Bool) {
        guard newStatus != self.isAROn else { return }
        
        self.isLoading = true
        self.update()
        
        if newStatus {
            MM?.scene.rootNode.getAllMusicianChildren().forEach({$0.scale = .init(x: 0.005, y: 0.005, z: 0.005); $0.position.x /= 10; $0.position.y /= 10; $0.position.z /= 10 }) // TODO: Check if there's a method to reduce the FOV of the camera to avoid dealing with that kind of things
        } else {
            NotificationCenter.default.post(name: .shouldStopAREngine, object: nil)
            MM?.scene.background.contents = CGColor(red: 0, green: 0, blue: 0, alpha: 1) // to remove the last frame from the camera
            MM?.scene.rootNode.getAllMusicianChildren().forEach({$0.scale = .init(x: 0.05, y: 0.05, z: 0.05); $0.position.x *= 10; $0.position.y *= 10; $0.position.z *= 10 })
            MM?.scene.rootNode.childNodes.first?.position = .init(0, 0, 0)
        }
        
        MM?.updateMusicianParticles(isAROn: newStatus)
        
        self.isAROn = newStatus
        self.isLoading = false
        self.update()
    }
    
    func toggleARMode() {
        self.setARMode(isOn: !isAROn)
    }
    
    func update() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
