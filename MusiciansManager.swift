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
    
    @Published var musicians: [String: (index: Int, musician: Musician)] = [:] // array of SCNNode's hash and their status
    
    init(scene: SCNScene) {
        self.scene = scene
    }
    
    func createMusician(index: Int) -> Musician {
        let musician = createUniqueMusician(verifyWithScene: scene)
        let name = "WWDC24-Musician-\(UUID().uuidString)"
        musician.node.name = name
        musicians.updateValue((index, musician), forKey: name)
        musician.setMuteStatus(isMuted: musician.status.isMuted)
        
        scene.rootNode.addChildNode(musician.node)
        
        return musician
    }
    
    func getMusicianWithNode(_ node: SCNNode) -> Musician? {
        return musicians.first(where: {$0.value.musician.node == node})?.value.musician
    }
    
    func updateCanBeHeardStatus() {
        for musician in self.musicians.values.map({$0.musician}) {
            if musician.status.isStopped {
                musician.hideParticles()
            } else {
                musician.showParticles(canBeHeard: self.musicianCanBeHeard(musician: musician))
            }
        }
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
            spotlightLight.intensity = 0
            
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
