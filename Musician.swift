//
//  Musician.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 03.02.2024.
//

import Foundation
import SceneKit


class Musician: ObservableObject {
    let manager: MusiciansManager
    let node: SCNNode
    let spotlightNode: SCNNode
    var sound: Sound?
    private(set) var status: MusicianStatus = .init()
    
    init(manager: MusiciansManager, node: SCNNode, spotlightNode: SCNNode, sound: Sound? = nil, status: MusicianStatus = .init()) {
        self.manager = manager
        self.node = node
        self.spotlightNode = spotlightNode
        self.sound = sound
        self.status = status
    }
    
    func setSound(_ sound: Sound) {
        if self.sound == nil {
            self.sound = sound
            sound.position = self.node.position.getBaseVector()
        }
    }
    
    func toggleMuteStatus() {
        setMuteStatus(isMuted: !self.status.isMuted)
    }
    
    func setMuteStatus(isMuted: Bool) {
        self.status.isMuted = isMuted
        self.showParticles(canBeHeard: manager.musicianCanBeHeard(musician: self))
        self.update()
    }
    
    func setSoloStatus(isSoloed: Bool) {
        self.status.isSoloed = isSoloed
        self.manager.updateCanBeHeardStatus()
        self.update()
    }
    
    func showParticles(canBeHeard: Bool? = nil) {
        if !self.status.isStopped {
            self.node.removeAllParticleSystems()
            
            if let canBeHeard = canBeHeard {
                self.node.addParticleSystem(createParticleSystem(type: canBeHeard ? .musicPlaying : .muted))
            } else {
                
                // set up all the particles
                self.node.addParticleSystem(createParticleSystem(type: manager.musicianCanBeHeard(musician: self) ? .musicPlaying : .muted))
            }
        }
    }
    
    func hideParticles() {
        self.node.removeAllParticleSystems()
    }
    
    func powerOnSpotlight() {
        guard !self.status.isSpotlightOn else { return }
        
        self.status.isSpotlightOn = true
        self.update()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        if let cgColor = self.spotlightNode.light?.color as! CGColor?, let color = SpotlightColor.getSpotlightColorFromCGColor(cgColor) { // TODO: Remove the force unwrap
            self.spotlightNode.light?.intensity = color.getPreferredIntensity()
        } else {
            self.spotlightNode.light?.intensity = SpotlightColor.defaultIntensity
        }
        
        SCNTransaction.commit()
        
        self.showParticles()
    }
    
    func powerOffSpotlight() {
        guard self.status.isSpotlightOn else { return }
        
        self.status.isSpotlightOn = false
        self.update()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        self.spotlightNode.light?.intensity = 0
        SCNTransaction.commit()
        
        self.hideParticles()
    }
    
    func toggleSpotlight() {
        if self.status.isSpotlightOn {
            self.powerOffSpotlight()
        } else {
            self.powerOnSpotlight()
        }
    }
    
    func goToNextColor() {
        switch self.status.spotlightColor {
        case .blue:
            changeSpotlightColor(color: .red)
        case .red:
            changeSpotlightColor(color: .green)
        case .green:
            changeSpotlightColor(color: .blue)
        }
    }
    
    func changeSpotlightColor(color: SpotlightColor) {
        guard self.status.spotlightColor != color else { return }
        
        self.status.spotlightColor = color
        self.update()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        self.spotlightNode.light?.color = color.getCGColor()
        self.spotlightNode.light?.intensity = self.status.isSpotlightOn ? color.getPreferredIntensity() : 0
        SCNTransaction.commit()
    }
    
    enum SpotlightColor {
        static let defaultIntensity: CGFloat = 50000
        
        case blue
        case red
        case green
        
        func getCGColor() -> CGColor {
            switch self {
            case .blue:
                return CGColor(red: 0, green: 0, blue: 1, alpha: 1)
            case .red:
                return CGColor(red: 1, green: 0, blue: 0, alpha: 1)
            case .green:
                return CGColor(red: 0, green: 1, blue: 0, alpha: 1)
            }
        }
        
        func getPreferredIntensity() -> CGFloat { // the luminance of each color is different so we have to set a custom intensity
            switch self {
            case .blue:
                return 50000
            case .red:
                return 25000
            case .green:
                return 10000
            }
        }
        
        static func getSpotlightColorFromCGColor(_ color: CGColor) -> SpotlightColor? {
            switch color {
            case SpotlightColor.red.getCGColor():
                return SpotlightColor.red
            case SpotlightColor.green.getCGColor():
                return SpotlightColor.green
            case SpotlightColor.blue.getCGColor():
                return SpotlightColor.blue
            default:
                return nil
            }
        }
    }

    private func createParticleSystem(type: ParticleSystem) -> SCNParticleSystem {
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 4
        particleSystem.particleSize = 0.3
        particleSystem.particleSizeVariation = 0
        particleSystem.emissionDuration = 1.5
        particleSystem.loops = true
        particleSystem.particleLifeSpan = 1.2
        particleSystem.particleVelocity = 8
        particleSystem.birthDirection = .constant // .random
        switch type {
        case .musicPlaying:
            particleSystem.particleImage = Bundle.main.path(forResource: "musicPlayingParticleTexture", ofType: "png")
        case .muted:
            particleSystem.particleImage = Bundle.main.path(forResource: "mutedParticleTexture", ofType: "png")
        }
        return particleSystem
    }
    
    private enum ParticleSystem {
        case musicPlaying
        case muted
    }
    
    private func update() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    struct MusicianStatus {
        var isMuted: Bool = false
        var isSoloed: Bool = false
        var isStopped: Bool = true
        
        var spotlightColor: SpotlightColor = .blue
        var isSpotlightOn: Bool = true
    }
    
    deinit {
        self.sound?.delegate = nil
    }
}

extension Musician: SoundDelegate {
    func soundDidChangeMuteStatus(isMuted: Bool) {
        self.setMuteStatus(isMuted: isMuted)
    }
    
    func soundDidChangeSoloStatus(isSoloed: Bool) {
        self.setSoloStatus(isSoloed: isSoloed)
    }
    
    func soundDidChangePlaybackStatus(isPlaying: Bool) {
        if isPlaying {
            self.status.isStopped = false
            self.update()
            self.powerOnSpotlight()
        } else {
            self.status.isStopped = true
            self.update()
            self.powerOffSpotlight()
        }
    }
}
