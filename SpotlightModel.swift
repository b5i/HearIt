//
//  SpotlightModel.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import Foundation

class SpotlightModel: ObservableObject {
    static let shared = SpotlightModel()
    
    private(set) var spotlight: Spotlight?
    
    private(set) var isEnabled: Bool = false
    
    func setNewSpotlight(to spotlight: Spotlight?) {
        self.spotlight = spotlight
        
        self.isEnabled = spotlight != nil
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func setSpotlightActiveStatus(to status: Bool) {
        self.isEnabled = status
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    struct Spotlight {
        let position: CGPoint
        let areaRadius: CGFloat
    }
}
