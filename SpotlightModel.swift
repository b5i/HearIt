//
//  SpotlightModel.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import Foundation
import SwiftUI

class SpotlightModel: ObservableObject {
    static let shared = SpotlightModel()
    
    private(set) var spotlights: [SpotlightType: (spotlight: Spotlight, isEnabled: Bool)] = [:]
    
    private(set) var isOn: Bool = false
    
    // Don't forget to add all the all-xxx main spotlight controllers to the init so they can be activated later on
    init() {
        self.spotlights = [.allMutes: (.init(position: .zero, areaRadius: .zero), false), .allSolos: (.init(position: .zero, areaRadius: .zero), false), .allSpotlightChanges: (.init(position: .zero, areaRadius: .zero), false)]
    }
        
    func setSpotlight(withType type: SpotlightType, to spotlight: Spotlight) {
        self.spotlights.updateValue((spotlight, self.spotlights[type]?.isEnabled ?? false), forKey: type)
                
        self.update()
    }
    
    func disactivateAllSpotlights() {
        for spotlightKey in spotlights.keys {
            spotlights[spotlightKey]?.isEnabled = false
        }
    }
    
    func setSpotlightActiveStatus(ofType type: SpotlightType, to status: Bool) {
        self.spotlights[type]?.isEnabled = status
        
        self.update()
    }
    
    func turnOnSpotlight() {
        self.isOn = true
        self.update()
    }
    
    func turnOffSpotlight() {
        self.isOn = false
        self.update()
    }
    
    func toggleSpotlight() {
        self.isOn.toggle()
        self.update()
    }
    
    /// Clear all the spotlight data, should not be called during a level.
    func clearCache() {
        self.spotlights = self.spotlights.filter({ spotlightType, _ in
            switch spotlightType {
            case .customWithAsset(name: _, uniqueIdentifier: let uniqueIdentifier):
                return uniqueIdentifier == nil // avoid clearing the spotlight that don't refer to an actual one but that control the others
            default:
                return false
            }
        })
    }
    
    struct Spotlight {
        let position: CGPoint
        let areaRadius: CGFloat
    }
        
    enum SpotlightType: Hashable {
        case playPause
        case door
        case lightBulb
        case playbackCapsule
        case loopActivation
        case loopLock
        case loopEditability
        case goForwardArrow
        case goBackwardArrow
        
        /// Create a custom spotlight zone, the name is like door, lightBulb or playPause and the uniqueIdentifier is an optional String that could be used like assetName is in spotlightChange(assetName: String) for instance.
        ///
        /// To reproduce the behavior of solo(assetName: String) you would typically do:
        /// ```swift
        /// extension SpotlightModel.SpotlightType {
        ///     static let newSoloAll(): SpotlightModel.SpotlightType = .customWithAsset(name: "newSolo", uniqueIdentifier: "")
        ///
        ///     static func newSolo(assetName: String) -> SpotlightModel.SpotlightType {
        ///         return .customWithAsset(name: "newSolo", uniqueIdentifier: assetName)
        ///     }
        /// }
        /// ```
        ///
        /// - Note: Make sure that you add the newSoloAll() in ``SpotlightModel/spotlights`` otherwise they won't have any effect.
        case customWithAsset(name: String, uniqueIdentifier: String?)
        
        /// Create a custom spotlight zone, the name is like door, lightBulb or playPause.
        ///
        /// To reproduce the behavior of playPause you would typically do:
        /// ```swift
        /// extension SpotlightModel.SpotlightType {
        ///     static let newPlayPause: SpotlightModel.SpotlightType = .custom(name: "newPlayPause")
        /// }
        case custom(name: String)
    }
    
    func update() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

extension SpotlightModel.SpotlightType {
    /// Spotlight all the mute buttons.
    static let allMutes: SpotlightModel.SpotlightType = .customWithAsset(name: "mute", uniqueIdentifier: nil)
    
    /// And mute(assetName: String) will only spotlight the mute button of the musician whose song's assetName is the same as the one provided here.
    static func mute(assetName: String) -> SpotlightModel.SpotlightType {
        return .customWithAsset(name: "mute", uniqueIdentifier: assetName)
    }
    
    /// Spotlight all the solo buttons.
    static let allSolos: SpotlightModel.SpotlightType = .customWithAsset(name: "solo", uniqueIdentifier: nil)
    
    /// And solo(assetName: String) will only spotlight the solo button of the musician whose song's assetName is the same as the one provided here.
    static func solo(assetName: String) -> SpotlightModel.SpotlightType {
        return .customWithAsset(name: "solo", uniqueIdentifier: assetName)
    }
    
    /// Spotlight all the spotlightChange buttons.
    static let allSpotlightChanges: SpotlightModel.SpotlightType = .customWithAsset(name: "spotlightChange", uniqueIdentifier: nil)
    
    /// And spotlightChange(assetName: String) will only spotlight the spotlightColor button of the musician whose song's assetName is the same as the one provided here except if assetName is nil then it will spotlight all the spotlightChange buttons.
    static func spotlightChange(assetName: String) -> SpotlightModel.SpotlightType {
        return .customWithAsset(name: "spotlightChange", uniqueIdentifier: assetName)
    }
}
