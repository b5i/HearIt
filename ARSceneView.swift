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
    let frame: CGRect
    
    @State private var stopObserver: NSObjectProtocol? = nil
    
    @State private var placementView: ARCoachingOverlayView? = nil
    
    @State private var pinchGestureObserver: NSObjectProtocol? = nil
    
    class SessionDelegate: NSObject, ARSessionDelegate, ARSCNViewDelegate, ARCoachingOverlayViewDelegate, UIGestureRecognizerDelegate {
        static let shared = SessionDelegate()
        
        var PM: PlaybackManager? = nil
        
        var arView: ARSCNView? = nil {
            didSet {
                hasAnchor = nil // reset it
                currentScale = nil
                previousScale = nil
            }
        }
        
        var hasAnchor: (status: HasAnchorStatus, anchor: ARAnchor?)? = nil
        
        var currentScale: Float? = nil
        
        var previousScale: Float? = nil
                
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
                if let currentScale = self.currentScale {
                    masterNode.scale = .init(currentScale, currentScale, currentScale)
                }
                self.hasAnchor = (.anchorFound, anchor)
            }
        }
        
        func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            if anchor == self.hasAnchor?.anchor, let scene = self.arView?.scene, let masterNode = scene.rootNode.childNodes.first {
                masterNode.transform = .init(anchor.transform)
                if let currentScale = self.currentScale {
                    masterNode.scale = .init(currentScale, currentScale, currentScale)
                }
            }
        }
                
        func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
            self.hasAnchor = (.placingInProgress, nil)

            guard let scene = self.arView?.scene, let masterNode = scene.rootNode.childNodes.first else { return }
            
            masterNode.transform = .init(.init(position: .zero))
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return self.hasAnchor?.anchor != nil
        }
        
        @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
            guard let scene = self.arView?.scene, let masterNode = scene.rootNode.childNodes.first else { return }
                        
            let gestureAtenuatorFactor: Float = 0.9
            
            let newGestureScale: Float = (Float(gesture.scale) - (previousScale ?? 1)) / gestureAtenuatorFactor + 1
            
            let maxScale: Float = 3
            let minScale: Float = 0.3
            
            if let currentScale = self.currentScale {
                self.currentScale = max(min(newGestureScale * currentScale, maxScale), minScale)
            } else {
                self.currentScale = max(min(newGestureScale, maxScale), minScale)
            }
            
            self.previousScale = Float(gesture.scale)
                        
            if let currentScale = self.currentScale {
                masterNode.scale = .init(currentScale, currentScale, currentScale)
            }
        }
                
        enum HasAnchorStatus {
            case anchorFound
            case noAnchor
            case placingInProgress
        }
    }
    
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: self.frame)
        
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
        
        placementView.center = sceneView.convert(sceneView.center, from:sceneView.superview)
        
        
        sceneView.addSubview(placementView)
                
        let pinchGesture = UIPinchGestureRecognizer(target: SessionDelegate.shared, action: #selector(SessionDelegate.shared.handlePinchGesture(_:)))
        
        pinchGesture.delegate = SessionDelegate.shared
                
        sceneView.addGestureRecognizer(pinchGesture)
        
        DispatchQueue.main.async {
            self.placementView = placementView
            self.stopObserver = NotificationCenter.default.addObserver(forName: .shouldStopAREngine, object: nil, queue: nil, using: { [weak sceneView] _ in
                SessionDelegate.shared.PM = nil
                SessionDelegate.shared.arView = nil
                sceneView?.session.pause()
                NotificationCenter.default.removeObserver(stopObserver as Any)
            })
            self.pinchGestureObserver = pinchGesture.observe(\.state, changeHandler: { gesture, _ in
                switch gesture.state {
                case .began:
                    SessionDelegate.shared.previousScale = nil
                case .cancelled:
                    SessionDelegate.shared.previousScale = nil
                case .failed:
                    SessionDelegate.shared.previousScale = nil
                default:
                    break;
                }
            })
        }
        
        sceneView.session.run(configuration)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        uiView.frame = self.frame
        self.placementView?.center = uiView.convert(uiView.center, from: uiView.superview)
    }
}
