//
//  Musician.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 03.02.2024.
//

import Foundation
import SceneKit

class Musician {
    let node: SCNNode
    let spotlightNode: SCNNode
    var sound: PlaybackManager.Sound?
    var status: MusicianStatus = .init()
    
    init(node: SCNNode, spotlightNode: SCNNode, sound: PlaybackManager.Sound? = nil, status: MusicianStatus = .init()) {
        self.node = node
        self.spotlightNode = spotlightNode
        self.sound = sound
        self.status = status
    }
    
    func setSound(_ sound: PlaybackManager.Sound) {
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
        self.showParticles()
    }
    
    func showParticles() {
        self.node.removeAllParticleSystems()
        
        // set up all the particles
        self.node.addParticleSystem(createParticleSystem(type: self.status.isMuted ? .muted : .musicPlaying))
    }
    
    func hideParticles() {
        self.node.removeAllParticleSystems()
    }
    
    func powerOnSpotlight() {
        guard !self.status.isSpotlightOn else { return }
        
        self.status.isSpotlightOn = true
        
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
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        self.spotlightNode.light?.color = color.getCGColor()
        self.spotlightNode.light?.intensity = color.getPreferredIntensity()
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
    
    struct MusicianStatus {
        var isMuted: Bool = false
        var isStopped: Bool = false
        
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
        self.setMuteStatus(isMuted: !isSoloed)
    }
    
    func soundDidChangePlaybackStatus(isPlaying: Bool) {
        if isPlaying {
            self.powerOnSpotlight()
        } else {
            self.powerOffSpotlight()
        }
    }
}
