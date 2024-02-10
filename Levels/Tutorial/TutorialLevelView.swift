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
    
    @State private var isLoadingScene: Bool = false
    @State private var isSceneLoaded: Bool = false
    @State private var scene: SCNScene?
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
        
    var body: some View {
        if isLoadingScene {
            ProgressView()
        } else if let scene = scene, let MM = MM {
            GeometryReader { geometry in
                VStack {
                    SceneStepsView(levelModel: LevelModel(steps: [
                        .init(text: "Welcome in \(appName)! To begin I'll teach you the basic controls that you have over the app: \n To go to the next instruction, click on the circled arrow at your right. \n If you can't find it, do a long press on the light bulb at the top right, it will highlight the right button."),
                        .init(text: "Let's start with the basics playback controls of the app. For the music to start playing, click on the rectangular button next to the timeline and its orange cursor.", passCondition: { mm, pm in
                            return pm.sounds.first?.value.timeObserver.isPlaying ?? false // - TODO: maybe set true as default value
                        }),
                        .init(text: "Great! You can now hear a little melody, to move forward or backwards in it, move the orange cursor to the time you want to listen to. If you move slowly, the bar will become bigger and let you select the precise second that you want to listent to."),
                        .init(text: "Let's move on to the controls that you have over the musician, you can mute and unmute the musician by clicking on the speaker icon under the musician or directly by clicking on the musician. Mute him to go to the next step.", passCondition: { mm, pm in
                            return pm.sounds.first?.value.isMuted ?? false
                        }),
                        .init(text: "If you have multiple musicians, you can decide to mute all of them except one, this operation is called the solo operation. To solo a musician, tap on the S button next to the mute/unmute one. Unmute and solo the first musician to continue.", passCondition: { mm, pm in
                            return !(pm.sounds.first?.value.isMuted ?? false) && (pm.sounds.first?.value.isSoloed ?? false)
                        }, stepAction: {
                            // TODO: add some other musicians
                        }),
                        .init(text: "In the coming levels you'll be asked to change the color of the musician, it actually refers to the color of the spotlight in front of him. To change its color, click on the spotlight or on the little firgure that is raising its hand. Clicking multiple times on the musician will switch between blue, red and green. Set the color of the spotlight to green to proceed.", passCondition: { mm, _ in
                            return mm.musicians.first?.value.musician.status.spotlightColor == .green
                        }, stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = nil
                        }),
                        .init(text: "Congrats you finished the tutorial phase and you now know everything about the controls of the app. To quit this tutorial, click on the opened door at the top right next to the light bulb button.", stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = .boleroTheme
                        })
                    ]), MM: MM, PM: PM)
                    NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM)
                }
            }
            .overlay(alignment: .topTrailing, content: {
                TopTrailingActionsView()
            })
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
        self.positionObserver = cameraNode.observe(\.transform, options: [.new], changeHandler: { [weak PM] /* avoid memory leak */ node, _ in
            var matrix = matrix_identity_float4x4
            matrix.columns.3 = .init(x: node.transform.m41, y: node.transform.m42, z: node.transform.m43, w: 1)
            PM?.listener.transform = matrix
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
                let newMusician = MM.createMusician(index: index)
                
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

#Preview {
    TutorialLevelView()
}
