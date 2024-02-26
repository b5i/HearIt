//
//  Musician.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 03.02.2024.
//

import Foundation
import SceneKit
import SceneKit.ModelIO

class Musician: ObservableObject {
    static var defaultMusicianTexture: CGImage {
        let musicianURL = Bundle.main.url(forResource: "art.scnassets/common_people@idle111", withExtension: "usdz")!
        let mdlAsset = MDLAsset(url: musicianURL)
        mdlAsset.loadTextures()
        let musicianNode = SCNNode(mdlObject: mdlAsset.object(at: 0))
        return (musicianNode.childNodes[1].childNodes[0].childNodes[0].childNodes[1].childNodes[0].childNodes[0].geometry?.materials[0].diffuse.contents as! MDLTexture).imageFromTexture()!.takeUnretainedValue() // TODO: remove those !
    }
    
    let manager: MusiciansManager
    let node: SCNNode
    let spotlightNode: SCNNode
    var sound: Sound?
     var name: String? = nil
    private(set) var status: MusicianStatus = .init()
    
    init(manager: MusiciansManager, node: SCNNode, spotlightNode: SCNNode, sound: Sound? = nil, name: String? = nil, status: MusicianStatus = .init()) {
        self.manager = manager
        self.node = node
        self.spotlightNode = spotlightNode
        self.sound = sound
        self.name = name
        self.status = status
    }
    
    func setSound(_ sound: Sound) {
        if self.sound == nil {
            self.sound = sound
            sound.position = self.node.position.getBaseVector()
        }
    }
    
    func show() {
        self.showParticles()
        self.node.isHidden = false
        self.status.isHidden = false
        self.update()
        self.manager.update()
    }
    
    func hide() {
        self.hideParticles()
        self.node.isHidden = true
        self.status.isHidden = true
        self.update()
        self.manager.update()
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
        self.manager.updateMusicianParticles()
        self.update()
    }
    
    func showParticles(canBeHeard: Bool? = nil, isAROn: Bool? = nil) {
        if !self.status.isStopped {
            self.node.removeAllParticleSystems()
            
            if let canBeHeard = canBeHeard {
                self.node.addParticleSystem(createParticleSystem(type: canBeHeard ? .musicPlaying : .muted, isAROn: isAROn ?? ARManager.shared.isAROn))
            } else {
                
                // set up all the particles
                self.node.addParticleSystem(createParticleSystem(type: manager.musicianCanBeHeard(musician: self) ? .musicPlaying : .muted, isAROn: isAROn ?? ARManager.shared.isAROn))
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
        
        if let cgColor = self.spotlightNode.light?.color, String(describing: cgColor).hasPrefix("<CGColor"), let validColor = cgColor as! CGColor?, let color = SpotlightColor.getSpotlightColorFromCGColor(validColor) { // TODO: Remove the force unwrap (apparently it's an xcode bug not to allow the optional cast)
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
            changeSpotlightColor(color: .green)
        case .red:
            changeSpotlightColor(color: .blue)
        case .green:
            changeSpotlightColor(color: .red)
        case .white:
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
        
    func setIntrumentTextureTo(_ instrumentType: InstrumentType) {
        let uiTexture = UIImage(cgImage: Self.defaultMusicianTexture).withRenderingMode(.alwaysOriginal)
        
        let text = instrumentType.rawValue
        let textColor = UIColor.orange
        let textFont = UIFont.systemFont(ofSize: 250)
                
        let format = UIGraphicsImageRendererFormat.default()
        let renderer = UIGraphicsImageRenderer(size: uiTexture.size, format: format)
                
        do {
            try renderer.runDrawingActions({ context in
                uiTexture.draw(in: .init(origin: .zero, size: uiTexture.size)) // fill the canvas with the base texture
                
                let textFontAttributes: [NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: textColor,
                ]
                
                let rect = CGRect(origin: .init(x: 690, y: 330), size: uiTexture.size)
                let attrString = NSAttributedString(string: text, attributes: textFontAttributes)
                
                context.cgContext.translateBy(x: rect.minX + attrString.size().width / 2, y: rect.minY + attrString.size().height / 2) // translate to the center of the rotation
                context.cgContext.rotate(by: instrumentType.getIntrumentAngle())
                context.cgContext.translateBy(x: -rect.minX - attrString.size().width / 2, y: -rect.minY - attrString.size().height / 2)
                attrString.draw(in: rect)
            }, completionActions: { context in
                guard let newImage = context.cgContext.makeImage() else { print("Could not create image"); return }
                self.node.childNodes[1].childNodes[0].childNodes[0].childNodes[1].childNodes[0].childNodes[0].geometry?.materials[0].diffuse.contents = newImage
            })
        } catch {
            print("Could not generate new texture: \(error.localizedDescription)")
        }
    }
    
    enum InstrumentType: String {
        case chords = "🎻"
        case flute = "🪈"
        case drums = "🥁"
        case maracas = "🪇"
        case piano = "🎹"
        case trumpet = "🎺"
        
        func getIntrumentAngle() -> CGFloat {
            switch self {
            case .chords, .flute, .trumpet:
                return 3 * .pi / 2
            case .drums, .piano, .maracas:
                return 3.2 * .pi / 2
            }
        }
    }
    
    /// powerOnOff: values that have a pair index means spotlight on, start the array by 0.0 if the player start with the spotlight off
    static func handleTime(sound: Sound, powerOnOff: [Double], colors: [(time: Double, color: Musician.SpotlightColor)]) {
        guard let musician = sound.infos.musician else { return }
        
        
        let currentTime = sound.timeObserver.currentTime
        
        guard sound.timeObserver.isPlaying else { musician.hideParticles(); return }
        
        if let currentSpotlightStatus = powerOnOff.firstIndex(where: {$0 > currentTime}) {
            if Int(currentSpotlightStatus) % 2 == 0 {
                musician.powerOnSpotlight()
                
                // Color animations

                if let currentColor = colors.first(where: {$0.time > currentTime})?.color {
                    musician.changeSpotlightColor(color: currentColor)
                }
            } else {
                musician.powerOffSpotlight()
                musician.changeSpotlightColor(color: .white)
            }
        } else {
            if powerOnOff.count % 2 == 0 {
                musician.powerOnSpotlight()
                
                // Color animations

                if let currentColor = colors.first(where: {$0.time > currentTime})?.color {
                    musician.changeSpotlightColor(color: currentColor)
                }
            } else {
                musician.powerOffSpotlight()
                musician.changeSpotlightColor(color: .white)
            }
        }
    }
    
    enum SpotlightColor {
        static let defaultIntensity: CGFloat = 50000
        
        case white
        
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
            case .white:
                return CGColor(red: 1, green: 1, blue: 1, alpha: 1)
            }
        }
        
        func getPreferredIntensity() -> CGFloat { // the luminance of each color is different so we have to set a custom intensity
            switch self {
            case .blue:
                return 50000
            case .red:
                return 25000
            case .green:
                return 15000
            case .white:
                return 15000
            }
        }
        
        static func getSpotlightColorFromCGColor(_ color: CGColor) -> SpotlightColor? {
            switch color {
            case SpotlightColor.red.getCGColor():
                return .red
            case SpotlightColor.green.getCGColor():
                return .green
            case SpotlightColor.blue.getCGColor():
                return .blue
            case SpotlightColor.white.getCGColor():
                return .white
            default:
                return nil
            }
        }
    }

    private func createParticleSystem(type: ParticleSystem, isAROn: Bool) -> SCNParticleSystem {
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 4
        particleSystem.particleSize = isAROn ? 0.03 : 0.3
        particleSystem.particleSizeVariation = 0
        particleSystem.emissionDuration = 1.5
        particleSystem.loops = true
        particleSystem.particleLifeSpan = 1.2
        particleSystem.particleVelocity = isAROn ? 0.8 : 8
        particleSystem.birthDirection = .constant // .random
        switch type {
        case .musicPlaying:
            particleSystem.particleImage = Bundle.main.path(forResource: "musicPlayingParticleTexture", ofType: "png")
        case .muted:
            particleSystem.particleImage = Bundle.main.path(forResource: "mutedParticleTexture", ofType: "png")
            particleSystem.particleColor = .red
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
        
        var spotlightColor: SpotlightColor = .white
        var isSpotlightOn: Bool = true
        
        var isHidden: Bool = false
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
            if let sound = self.sound, let timeHandler = sound.timeHandler {
                timeHandler(sound)
            } else {
                self.powerOnSpotlight()
            }
        } else {
            self.status.isStopped = true
            self.update()
            self.powerOffSpotlight()
        }
    }
}
