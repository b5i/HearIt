//
//  SpotlightModel.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import Foundation

class SpotlightModel: ObservableObject {
    static let shared = SpotlightModel()
    
    private(set) var spotlights: [SpotlightType: (spotlight: Spotlight, isEnabled: Bool)] = [:]
        
    func setSpotlight(withType type: SpotlightType, to spotlight: Spotlight) {
        self.spotlights.updateValue((spotlight, self.spotlights[type]?.isEnabled ?? false), forKey: type)
                
        self.update()
    }
    
    func setSpotlightActiveStatus(ofType type: SpotlightType, to status: Bool) {
        self.spotlights[type]?.isEnabled = status
        
        self.update()
    }
    
    struct Spotlight {
        let position: CGPoint
        let areaRadius: CGFloat
    }
    
    enum SpotlightType {
        case playPause
        case mute
        case solo
        case spotlightChange
        case door
    }
    
    func update() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
