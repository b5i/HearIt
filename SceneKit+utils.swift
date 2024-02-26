//
//  SceneKit+utils.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 24.02.2024.
//

import Foundation
import SceneKit

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
                if let potentialNode = child.getFirstCamera() {
                    node = potentialNode
                }
            }
        }
        return node
    }
    
    func getFirstAmbientLight() -> SCNNode? {
        var node: SCNNode? = nil
        for child in self.childNodes {
            if child.name?.hasPrefix("WWDC24-AmbientLight") == true {
                node = child
                break
            } else {
                if let potentialNode = child.getFirstAmbientLight() {
                    node = potentialNode
                }
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
                if let potentialNode = parent.getMusicianParent() {
                    node = potentialNode
                }
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
    
    func getAllChidren() -> [SCNNode] {
        var nodeList: [SCNNode] = []
        for child in self.childNodes {
            nodeList.append(child)
            nodeList.append(contentsOf: child.getAllChidren())
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
                if let potentialNode = child.getMusicianChild(withName: name) {
                    node = potentialNode
                }
            }
        }
        return node
    }
}
