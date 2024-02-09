//
//  TutorialLevelView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 04.02.2024.
//

import SwiftUI
import PHASE
import SceneKit

struct TutorialLevelView: View {
    @StateObject private var PM = PlaybackManager()
    
    @StateObject private var levelModel = LevelModel()
    
    @State private var isLoadingScene: Bool = false
    @State private var isSceneLoaded: Bool = false
    @State private var scene: SCNScene?
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
    
    //@State private var MM: MusiciansManager?
    
    var body: some View {
        if isLoadingScene {
            ProgressView()
        } else if let scene = scene, let MM = MM {
            GeometryReader { geometry in
                VStack {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(.cyan.opacity(0.3))
                            .background(RoundedRectangle(cornerRadius: 10).fill(.cyan))
                        if let currentStep = levelModel.currentStep {
                            VStack {
                                Text(currentStep.text)
                                HStack {
                                    Image(systemName: "arrow.backward.circle.fill")
                                        .onTapGesture {
                                            levelModel.goToPreviousStep()
                                        }
                                        //.opacity(levelModel.previousStepExists ? 1 : 0)
                                    Spacer()
                                    Image(systemName: "arrow.forward.circle.fill")
                                        .onTapGesture {
                                            levelModel.goToNextStep(musicianManager: MM, playbackManager: PM)
                                        }
                                }
                            }
                        }
                    }
                    .frame(width: geometry.size.width * 0.75, height: levelModel.currentStep != nil ? geometry.size.height * 0.2 : 0)
                    .background(.black)
                    NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM)
                }
            }
        } else {
            Color.clear
                .onAppear {
                    if self.scene == nil && !self.isLoadingScene {
                        self.isLoadingScene = true
                        let scene = createScene()
                        self.scene = scene
                        let manager = MusiciansManager(scene: scene)
                        self.MM = manager
                        Task {
                            await setupTutorial(MM: manager)
                            DispatchQueue.main.async {
                                self.isLoadingScene = false
                                self.isSceneLoaded = true
                            }
                        }
                    }
                }
        }
    }
    
    private class LevelModel: ObservableObject {
        struct Step {
            var text: String
            var passCondition: (MusiciansManager, PlaybackManager) -> Bool
        }
        
        @Published private var steps: [Step] = [
            Step(text: "Welcome in [name of the app]! To begin I'll teach you the basic controls that you have over the app: \n To go to the ", passCondition: {_,_  in return true}),
            Step(text: "Please put the player in green", passCondition: { mm, pm in
                return mm.musicians.first?.value.status.spotlightColor == .green
            })
        ]
        
        @Published private var currentStepIndex: Int = 0
        
        var currentStep: Step? {
            if self.steps.count > self.currentStepIndex && self.currentStepIndex != -1 {
                return self.steps[currentStepIndex]
            } else {
                return nil
            }
        }
        
        var previousStepExists: Bool {
            return self.currentStepIndex != 0 && !self.steps.isEmpty
        }
        
        func goToPreviousStep() {
            if self.currentStepIndex != 0 {
                withAnimation {
                    self.currentStepIndex -= 1
                }
            }
        }
        
        func goToNextStep(musicianManager: MusiciansManager, playbackManager: PlaybackManager) {
            if self.steps[self.currentStepIndex].passCondition(musicianManager, playbackManager) {
                if self.steps.count > self.currentStepIndex + 1 {
                    withAnimation {
                        self.currentStepIndex += 1
                    }
                } else {
                    withAnimation {
                        self.currentStepIndex = -1
                    }
                }
            }
        }
    }
    
    private func createScene() -> SCNScene {
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/musicScene.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.name = "WWDC24-Camera"
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera and observe its position to adapt the listener position in space
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        self.positionObserver = cameraNode.observe(\.transform, options: [.new], changeHandler: { node, _ in
            var matrix = matrix_identity_float4x4
            matrix.columns.3 = .init(x: node.transform.m41, y: node.transform.m42, z: node.transform.m43, w: 1)
            PM.listener.transform = matrix
        })
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        lightNode.light?.intensity = 100
        scene.rootNode.addChildNode(lightNode)
        
        let spotlightLightNode = SCNNode()
        spotlightLightNode.light = SCNLight()
        spotlightLightNode.light?.type = .spot
        spotlightLightNode.light?.intensity = 1000
        scene.rootNode.addChildNode(spotlightLightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
                
        return scene
    }
    
    private func setupTutorial(MM: MusiciansManager) async {
        func createMusician(withSongName songName: String, audioLevel: Double = 0, index: Int) async {
            if PM.sounds[songName] == nil {
                let newMusician = MM.createMusician()
                
                newMusician.node.scale = .init(x: 0.05, y: 0.05, z: 0.05)
                newMusician.node.position = .init(x: 4 * Float(index), y: 0, z: 0)
                
                let distanceParameters = PHASEGeometricSpreadingDistanceModelParameters()
                distanceParameters.rolloffFactor = 0.5
                distanceParameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 30)
                
                
                
                let result = await PM.loadSound(soundPath: songName, emittedFromPosition: .init(), options: .init(distanceModelParameters: distanceParameters, playbackMode: .looping, audioCalibration: (.relativeSpl, audioLevel)))
                
                switch result {
                case .success(let sound):
                    newMusician.setSound(sound)
                    newMusician.soundDidChangePlaybackStatus(isPlaying: false)
                    sound.delegate = newMusician
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
        
        await createMusician(withSongName: "TutorialSounds/la_panterra.mp3", audioLevel: -8, index: 0)
        
        /*
        await createMusician(withSongName: "TutorialSounds/bolero_1.m4a", index: 0)
        await createMusician(withSongName: "TutorialSounds/bolero_2.m4a", index: 1)
        await createMusician(withSongName: "TutorialSounds/bolero_3.m4a", index: 2)
        await createMusician(withSongName: "TutorialSounds/bolero_4.m4a", index: 3)
        await createMusician(withSongName: "TutorialSounds/bolero_5.m4a", index: 4)
        await createMusician(withSongName: "TutorialSounds/bolero_6.m4a", index: 5)
        await createMusician(withSongName: "TutorialSounds/bolero_7.m4a", index: 6)
        */
         
       /*
        await createMusician(withSongName: "TutorialSounds/tutorial_drums.m4a", index: 0)
        await createMusician(withSongName: "TutorialSounds/tutorial_hihats.m4a", index: 1)
        await createMusician(withSongName: "TutorialSounds/tutorial_kick.m4a", index: 2)
        await createMusician(withSongName: "TutorialSounds/tutorial_synth.m4a", audioLevel: -3, index: 3)
         */
                
        //self.PM.restartAndSynchronizeSounds()
    }
}

extension View {
    /// Apply a spotlight effect on the view.
    func spotlight(areaRadius: CGFloat = 10, isEnabled: Bool = true) -> some View {
        if #available(iOS 17.0, *) {
            return GeometryReader { geometry in
                self.onAppear {
                    SpotlightModel.shared.setNewSpotlight(to: SpotlightModel.Spotlight(position: CGPoint(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).midY), areaRadius: areaRadius))
                    SpotlightModel.shared.setSpotlightActiveStatus(to: isEnabled)
                }
            }
        } else {
            return self
        }
    }
}

class SpotlightModel: ObservableObject {
    static let shared = SpotlightModel()
    
    private(set) var spotlight: Spotlight?
    
    private(set) var isEnabled: Bool = false
    
    func setNewSpotlight(to spotlight: Spotlight?) {
        self.spotlight = spotlight
        
        self.isEnabled = spotlight != nil
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func setSpotlightActiveStatus(to status: Bool) {
        self.isEnabled = status
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    struct Spotlight {
        let position: CGPoint
        let areaRadius: CGFloat
    }
}

#Preview {
    TutorialLevelView()
}
