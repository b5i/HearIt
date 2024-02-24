//
//  MusicianManager.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.01.2024.
//

import SceneKit
import SceneKit.ModelIO
import AVFoundation
import PHASE

class MusiciansManager: ObservableObject {
    let scene: SCNScene
    
    @Published var musicians: [String: (index: Int, musician: Musician)] = [:] // array of SCNNode's hash and their status
    
    init(scene: SCNScene) {
        self.scene = scene
    }
    
    @MainActor
    func createMusician(withSongName songName: String, audioLevel: Double = 0, index: Int, PM: PlaybackManager, color: Musician.SpotlightColor = .white, name: String? = nil, handler: ((Sound) -> ())? = nil, instrument: Musician.InstrumentType? = nil) async {
        if PM.sounds[songName] == nil {
            let newMusician = self.createMusician(index: index)
            
            newMusician.node.scale = .init(x: 0.05, y: 0.05, z: 0.05)
            newMusician.node.position = .init(x: 4 * Float(index), y: 0, z: 0)
            
            let distanceParameters = PHASEGeometricSpreadingDistanceModelParameters()
            distanceParameters.rolloffFactor = 0.5
            distanceParameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 30)
            
            
            
            let result = await PM.loadSound(soundPath: songName, emittedFromPosition: .init(), options: .init(distanceModelParameters: distanceParameters, playbackMode: .looping, audioCalibration: (.relativeSpl, audioLevel)))
            
            switch result {
            case .success(let sound):
                sound.infos.musician = newMusician
                sound.infos.musiciansManager = self
                sound.infos.playbackManager = PM
                sound.timeHandler = handler
                newMusician.name = name
                newMusician.setSound(sound)
                newMusician.soundDidChangePlaybackStatus(isPlaying: false)
                newMusician.changeSpotlightColor(color: color)
                if let instrument = instrument {
                    newMusician.setIntrumentTextureTo(instrument)
                }
                sound.delegate = newMusician
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func createMusician(index: Int) -> Musician {
        let musician = createUniqueMusician(verifyWithScene: scene)
        let name = "WWDC24-Musician-\(UUID().uuidString)"
        musician.node.name = name
        musicians.updateValue((index, musician), forKey: name)
        musician.setMuteStatus(isMuted: musician.status.isMuted)
                
        scene.rootNode.childNodes.first?.addChildNode(musician.node)
        
        return musician
    }
    
    func getMusicianWithNode(_ node: SCNNode) -> Musician? {
        return musicians.first(where: {$0.value.musician.node == node})?.value.musician
    }
    
    func updateMusicianParticles(isAROn: Bool? = nil) {
        for musician in self.musicians.values.map({$0.musician}) {
            if musician.status.isStopped {
                musician.hideParticles()
            } else {
                musician.showParticles(canBeHeard: self.musicianCanBeHeard(musician: musician), isAROn: isAROn ?? ARManager.shared.isAROn)
            }
        }
    }
    
    func placeCameraToDefaultPosition() {
        self.scene.rootNode.getFirstCamera()?.position = SCNVector3(x: 0, y: 2, z: 12)
    }
    
    func recenterCamera() {
        self.scene.rootNode.getFirstCamera()?.position.x = Float((self.musicians.count - 1) * 2)
    }
    
    private func createUniqueMusician(verifyWithScene scene: SCNScene) -> Musician {
        func makeMusician() -> Musician {
            let musicianURL = Bundle.main.url(forResource: "art.scnassets/common_people@idle111", withExtension: "usdz")!
            let mdlAsset = MDLAsset(url: musicianURL)
            mdlAsset.loadTextures()
            let musicianNode = SCNNode(mdlObject: mdlAsset.object(at: 0))
            musicianNode.rotation.y = 1
            musicianNode.rotation.w += Float.pi / 2
            //let musicianScene = SCNScene(named: "art.scnassets/common_people@idle.scn")!
            //let musicianNode = musicianScene.rootNode.childNode(withName: "Body-Main", recursively: true)!
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
            
            spotlightNode.eulerAngles = SCNVector3(x: .pi * 8/9, y: .pi/2 /* or 0 if we use the .scn asset*/, z: .pi)
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
            
            let spotlightLightNode = SCNNode()
            let spotlightLight = SCNLight()
            spotlightLightNode.eulerAngles = SCNVector3(x: .pi, y: 0, z: 0)
            spotlightLightNode.light = spotlightLight
            spotlightLight.type = .area
            spotlightLight.color = Musician.SpotlightColor.white.getCGColor()
            spotlightLight.intensity = 0
            spotlightLight.categoryBitMask = 0x1 << self.musicians.count
            
            // prevent the light from other musicians to reflect on this musician
            musicianNode.categoryBitMask = 0x1 << self.musicians.count
            spotlightLight.categoryBitMask = 0x1 << self.musicians.count
            musicianNode.getAllChidren().forEach({$0.categoryBitMask = 0x1 << self.musicians.count})
                        
            spotlightFlashNode.addChildNode(spotlightLightNode)

            return Musician(manager: self, node: musicianNode, spotlightNode: spotlightLightNode)
        }
        while true {
            let musician = makeMusician()
            if !scene.rootNode.childNodes.contains(where: {$0.hash == musician.node.hash}) { // make sure that we will be able to identify the musician (no doubles) TODO: Check with the address instead
                return musician
            }
        }
    }
    
    func musicianCanBeHeard(musician: Musician) -> Bool {
        if musician.status.isSoloed {
            return true
        }
        if musician.status.isMuted {
            return false
        }
        if self.musicians.contains(where: {$0.value.musician.status.isSoloed}) {
            return false
        } else {
            return true
        }
    }
    
    func update() {
        self.objectWillChange.send()
    }
}
