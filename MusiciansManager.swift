//
//  MusicianManager.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.01.2024.
//

import SceneKit
import AVFoundation

class MusiciansManager: ObservableObject {
    let scene: SCNScene
    
    @Published var musicians: [String: Musician] = [:] // array of SCNNode's hash and their status
    
    init(scene: SCNScene) {
        self.scene = scene
    }
    
    func createMusician() -> Musician {
        let musician = createUniqueMusician(verifyWithScene: scene)
        let name = "WWDC24-Musician-\(UUID().uuidString)"
        musician.node.name = name
        musicians.updateValue(musician, forKey: name)
        musician.setMuteStatus(isMuted: musician.status.isMuted)
        
        scene.rootNode.addChildNode(musician.node)
        
        return musician
    }
    
    func getMusicianWithNode(_ node: SCNNode) -> Musician? {
        return musicians.first(where: {$0.value.node == node})?.value
    }
    
    private func createUniqueMusician(verifyWithScene scene: SCNScene) -> Musician {
        func makeMusician() -> Musician {
            let musicianScene = SCNScene(named: "art.scnassets/common_people@idle.scn")!
            let musicianNode = musicianScene.rootNode.childNode(withName: "Body-Main", recursively: true)!
            musicianNode.removeFromParentNode()
            
            let spotlightScene = SCNScene(named: "art.scnassets/cleanSpotlight.scn")!
            let spotlightNode = SCNNode()
            spotlightNode.name = "Spotlight-RootNode"
            
            musicianNode.addChildNode(spotlightNode)
            
            let spotlightSupportNode = spotlightScene.rootNode.childNode(withName: "Spotlight-Cover", recursively: true)!
            spotlightSupportNode.removeFromParentNode()
            spotlightNode.addChildNode(spotlightSupportNode)
            
            
            let spotlightFlashNode = spotlightScene.rootNode.childNode(withName: "Spotlight-Flash", recursively: true)!
            spotlightFlashNode.removeFromParentNode()
            spotlightNode.addChildNode(spotlightFlashNode)
            
             
            spotlightNode.scale = SCNVector3(x: 60, y: 60, z: 60)
            //spotlightNode.eulerAngles = SCNVector3(x: .pi / 2, y: 0, z: 0)
            //spotlightNode.pivot = .init(m11: 1, m12: 0, m13: 0, m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: 0, m32: 0, m33: 1, m34: 0, m41: 0, m42: 1.3, m43: 1.4, m44: 1) // top of the musician position
            
            spotlightSupportNode.transform.m42 += 1
            spotlightFlashNode.transform.m42 += 1
            
            spotlightNode.eulerAngles = SCNVector3(x: .pi * 8/9, y: 0, z: .pi)
            spotlightNode.pivot = .init(m11: 1, m12: 0, m13: 0, m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: 0, m32: 0, m33: 1, m34: 0, m41: 0  /* side axis */, m42: 0.8 /* z axis */ , m43: 0.9 /* front axis */, m44: 1)
                        
            /*
            let audioEngine  = AVAudioEngine()
            let filePath: String = Bundle.main.path(forResource: "kick.m4a", ofType: nil)!
            var audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
            print("\(filePath)")
            let fileURL: URL = URL(fileURLWithPath: filePath)
            let audioFile = try! AVAudioFile(forReading: fileURL)
            
            let audioFormat = audioFile.processingFormat
            let audioFrameCount = UInt32(audioFile.length)
            //AVAudioCompressedBuffer(format: audioFormat, packetCapacity: audioFrameCount)
            //AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)!
            let audioFileBuffer = AVAudioCompressedBuffer(format: audioFormat, packetCapacity: audioFrameCount)

            do{
                //try audioFile.read(into: audioFileBuffer)
            } catch{
                print("over")
            }
            let mainMixer = audioEngine.mainMixerNode
            audioEngine.attach(audioFilePlayer)
            audioEngine.connect(audioFilePlayer, to:mainMixer, format: audioFileBuffer.format)
            try? audioEngine.start()
            audioFilePlayer.play()
            //audioFilePlayer.scheduleBuffer(audioFileBuffer, at: nil, options:AVAudioPlayerNodeBufferOptions.loops)
           
            let player = SCNAudioPlayer(avAudioNode: audioFilePlayer)
            musicianNode.addAudioPlayer(player)
            */
            
            
            let spotlightFlashGeometry = SCNPlane(width: 0.15, height: 0.15)
            spotlightFlashGeometry.cornerRadius = 0.5
            
            let spotlightLightNode = SCNNode()
            //spotlightLightNode.geometry = spotlightFlashGeometry
            let spotlightLight = SCNLight()
            spotlightLightNode.eulerAngles = SCNVector3(x: .pi, y: 0, z: 0)
            spotlightLightNode.light = spotlightLight
            //spotlightLightNode.scale = SCNVector3(x: 10, y: 10, z: 10)
            spotlightLight.type = .area
            spotlightLight.color = Musician.SpotlightColor.blue.getCGColor()
            spotlightLight.intensity = Musician.SpotlightColor.blue.getPreferredIntensity()
            
            //spotlightLight.spotInnerAngle = 180
            
            spotlightFlashNode.addChildNode(spotlightLightNode)
            
            /* can't be added at the moment as there is a limit of 8 lights
            let spotlightLightNode2 = SCNNode()
            spotlightLightNode2.transform.m43 += 0.7 // make the light reflect on the blindfolds of the spotlight
            let spotlightLight2 = SCNLight()
            spotlightLightNode2.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
            spotlightLightNode2.light = spotlightLight2
            //spotlightLightNode.scale = SCNVector3(x: 10, y: 10, z: 10)
            spotlightLight2.type = .spot
            spotlightLight2.color = CGColor(red: 0, green: 0, blue: 1, alpha: 1)
            spotlightLight2.intensity = 100
            spotlightFlashNode.addChildNode(spotlightLightNode2)
            
            let spotlightLightNode3 = SCNNode()
            spotlightLightNode3.transform.m43 += 0.3 // make the illusion that the light is coming from the yellow part of the spotlight
            let spotlightLight3 = SCNLight()
            spotlightLightNode3.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
            spotlightLightNode3.light = spotlightLight2
            spotlightLight3.type = .spot
            spotlightLight3.color = CGColor(red: 0, green: 0, blue: 1, alpha: 1)
            spotlightLight3.intensity = 100
            spotlightFlashNode.addChildNode(spotlightLightNode3)
             */

            
            /*
            spotlightLight.shadowColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
            spotlightLight.shadowRadius = 10
            spotlightLight.castsShadow = true
            spotlightLight.shadowMode = .deferred
             */
            
            return Musician(node: musicianNode, spotlightNode: spotlightLightNode)
        }
        while true {
            let musician = makeMusician()
            if !scene.rootNode.childNodes.contains(where: {$0.hash == musician.node.hash}) { // make sure that we will be able to identify the musician (no doubles) TODO: Check with the address instead
                return musician
            }
        }
    }
}

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
        self.node.removeAllParticleSystems()
        self.node.addParticleSystem(createParticleSystem(type: isMuted ? .muted : .musicPlaying))
        self.status.isMuted = isMuted
        self.sound?.isMuted = isMuted
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
    }
    
    func powerOffSpotlight() {
        guard self.status.isSpotlightOn else { return }
        
        self.status.isSpotlightOn = false
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        self.spotlightNode.light?.intensity = 0
        SCNTransaction.commit()
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
}

extension simd_float3 {
    func getSceneVector() -> SCNVector3 {
        return SCNVector3(x: self.x, y: self.y, z: self.z)
    }
}

extension SCNVector3 {
    func getBaseVector() -> simd_float3 {
        return simd_float3(x: self.x, y: self.y, z: self.z)
    }
}

extension SCNScene {
    func getMusician(withName name: String) -> SCNNode? {
        return self.rootNode.getMusicianChild(withName: name)
    }
}

extension SCNNode {
    func getFirstCamera() -> SCNNode? {
        var node: SCNNode? = nil
        for child in self.childNodes {
            if child.name?.hasPrefix("WWDC24-Camera") == true {
                node = child
                break
            } else {
                node = child.getFirstCamera()
            }
        }
        return node
    }
    
    var isSpotlightPart: Bool {
        var result: Bool = false
        
        if self.name?.hasPrefix("Spotlight") == true { return true }
        else if let parent = self.parent {
            if parent.name?.hasPrefix("Spotlight") == true {
                result = true
            } else {
                result = parent.isSpotlightPart
            }
        }
         
        return result
    }
    
    var isMusicianBodyPart: Bool {
        var result: Bool = false
        
        if self.name?.hasPrefix("Body") == true { return true }
        else if let parent = self.parent {
            if parent.name?.hasPrefix("Body") == true {
                result = true
            } else {
                result = parent.isSpotlightPart
            }
        }
         
        return result
    }
    
    func getMusicianParent() -> SCNNode? {
        var node: SCNNode? = nil
        if let parent = self.parent, let parentName = parent.name {
            if parentName.hasPrefix("WWDC24-Musician-") {
                node = parent
            } else {
                node = parent.getMusicianParent()
            }
        }
        return node
    }
    
    func getAllMusicianChildren() -> [SCNNode] {
        var nodeList: [SCNNode] = []
        for child in self.childNodes {
            if child.name?.hasPrefix("WWDC24-Musician-") == true {
                nodeList.append(child)
            }
            nodeList.append(contentsOf: child.getAllMusicianChildren())
        }
        return nodeList
    }
    
    func getMusicianChild(withName name: String) -> SCNNode? {
        var node: SCNNode? = nil
        for child in self.childNodes {
            if child.name?.hasPrefix("WWDC24-Musician-\(name)") == true {
                node = child
                break
            } else {
                node = child.getMusicianChild(withName: name)
            }
        }
        return node
    }
}
