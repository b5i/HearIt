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
    
    struct Spotlight {
        let position: CGPoint
        let areaRadius: CGFloat
    }
    
    enum SpotlightType: Hashable {
        case playPause
        case door
        case lightBulb
        case playbackCapsule
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
    static let allMutes: SpotlightModel.SpotlightType = .customWithAsset(name: "mute", uniqueIdentifier: "")
    
    /// And mute(assetName: String) will only spotlight the mute button of the musician whose song's assetName is the same as the one provided here.
    static func mute(assetName: String) -> SpotlightModel.SpotlightType {
        return .customWithAsset(name: "mute", uniqueIdentifier: assetName)
    }
    
    /// Spotlight all the solo buttons.
    static let allSolos: SpotlightModel.SpotlightType = .customWithAsset(name: "solo", uniqueIdentifier: "")
    
    /// And solo(assetName: String) will only spotlight the solo button of the musician whose song's assetName is the same as the one provided here.
    static func solo(assetName: String) -> SpotlightModel.SpotlightType {
        return .customWithAsset(name: "solo", uniqueIdentifier: assetName)
    }
    
    /// Spotlight all the spotlightChange buttons.
    static let allSpotlightChanges: SpotlightModel.SpotlightType = .customWithAsset(name: "spotlightChange", uniqueIdentifier: "")
    
    /// And spotlightChange(assetName: String) will only spotlight the spotlightColor button of the musician whose song's assetName is the same as the one provided here except if assetName is nil then it will spotlight all the spotlightChange buttons.
    static func spotlightChange(assetName: String) -> SpotlightModel.SpotlightType {
        return .customWithAsset(name: "spotlightChange", uniqueIdentifier: assetName)
    }
}

extension View {
    /// Apply a spotlight effect on the view that can be activated later on using ``SpotlightModel/setSpotlightActiveStatus(ofType:to:)``.
    ///
    /// - Warning: You should **never** set the spotlight property for a type created with customWithAsset with a nil for the customAsset property (otherwise it'll activate every spotlight that has the same name).
    func spotlight(type: SpotlightModel.SpotlightType, areaRadius: CGFloat = 30, customPosition: (x: Double?, y: Double?) = (nil, nil)) -> some View {
        return self.overlay(alignment: .center) {
            GeometryReader { geometry in
                let spotlightCenter = CGPoint(x: customPosition.x ?? geometry.frame(in: .global).midX, y: customPosition.y ?? geometry.frame(in: .global).midY)
                Color.clear
                    .onAppear {
                        SpotlightModel.shared.setSpotlight(withType: type, to: SpotlightModel.Spotlight(position: spotlightCenter, areaRadius: areaRadius))
                    }
                    .id(spotlightCenter) // so it updates automatically
            }
        }
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
}
