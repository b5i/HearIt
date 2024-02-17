//
//  ARSceneView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 14.02.2024.
//

import SwiftUI
import ARKit

struct ARSceneView: UIViewRepresentable {
    let scene: SCNScene
    let musicianManager: MusiciansManager
    let playbackManager: PlaybackManager
    
    @State private var stopObserver: NSObjectProtocol? = nil
    
    class SessionDelegate: NSObject, ARSessionDelegate, ARSCNViewDelegate, ARCoachingOverlayViewDelegate {
        static let shared = SessionDelegate()
        
        var PM: PlaybackManager? = nil
        
        var arView: ARSCNView? = nil {
            didSet {
                hasAnchor = nil // reset it
            }
        }
        
        var hasAnchor: (status: HasAnchorStatus, anchor: ARAnchor?)? = nil
                
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            if let headphonesPosition = PM?.headphonesPosition {
                PM?.listener.worldTransform = matrix_multiply(frame.camera.transform, headphonesPosition.toSIMDMatrix())
            } else {
                PM?.listener.worldTransform = frame.camera.transform
            }
        }
        
        func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if self.hasAnchor?.status != .anchorFound, let scene = self.arView?.scene, let masterNode = scene.rootNode.childNodes.first {
                masterNode.transform = .init(anchor.transform)
                self.hasAnchor = (.anchorFound, anchor)
            }
        }
        
        func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            if anchor == self.hasAnchor?.anchor, let scene = self.arView?.scene, let masterNode = scene.rootNode.childNodes.first {
                masterNode.transform = .init(anchor.transform)
            }
        }
                
        func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) { // TODO: center this overlay or hide it
            self.hasAnchor = (.placingInProgress, nil)

            guard let anchorNode = self.arView?.scene.rootNode.childNodes.first, let scene = self.arView?.scene, let masterNode = scene.rootNode.childNodes.first else { return }
            
            masterNode.transform = .init(.init(position: .zero))
        }
        
        enum HasAnchorStatus {
            case anchorFound
            case noAnchor
            case placingInProgress
        }
    }
    
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal] // https://developer.apple.com/documentation/arkit/arscnview/providing_3d_virtual_content_with_scenekit
        
        sceneView.session.delegate = SessionDelegate.shared
        sceneView.delegate = SessionDelegate.shared
        SessionDelegate.shared.PM = self.playbackManager
        SessionDelegate.shared.arView = sceneView
        sceneView.scene = self.scene
        
        let placementView = ARCoachingOverlayView()

        placementView.activatesAutomatically = true
        placementView.delegate = SessionDelegate.shared
        placementView.goal = .horizontalPlane
        placementView.session = sceneView.session
        
        placementView.center = sceneView.center
        
        sceneView.addSubview(placementView)
                
        DispatchQueue.main.async {
            self.stopObserver = NotificationCenter.default.addObserver(forName: .shouldStopAREngine, object: nil, queue: nil, using: { [weak sceneView] _ in
                SessionDelegate.shared.PM = nil
                SessionDelegate.shared.arView = nil
                sceneView?.session.pause()
                NotificationCenter.default.removeObserver(stopObserver as Any)
            })
        }
        
        sceneView.session.run(configuration)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
