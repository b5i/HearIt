//
//  BoleroLevelTestView.swift
//
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI
import PHASE
import SceneKit

struct BoleroLevelTestView: View {
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
                    LevelModel.TextStep(text: "I just added a few musicians to complicate a bit the thing. Let's see if you understood the theory correctly.", stepAction: {
                        SpotlightModel.shared.disactivateAllSpotlights()
                    }),
                    LevelModel.ViewStep(view: {
                        VStack {
                            Text("Your goal is to find what musician is playing what element, each element can be played by multiple musicians at the same time. To enter your choice, change the color of the musician according to what you think he playing with the color indicated under this text. \n  Once you're finished, click on the right arrow to validate your results. Good luck!") // TODO: "remanier"
                            HStack {
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.blue)
                                        .frame(width: 100, height: 40)
                                    Text("Theme")
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.green)
                                        .frame(width: 180, height: 40)
                                    Text("Accompaniement")
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.red)
                                        .frame(width: 100, height: 40)
                                    Text("Bassline")
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                            }
                        }
                    }, passCondition: { mm,_ in
                        for musician in mm.musicians.values.map({$0.musician}) {
                            if musician.sound?.infos.assetName.hasPrefix("bolero_theme") == true && musician.status.spotlightColor != .blue {
                                return false
                            } else if musician.sound?.infos.assetName.hasPrefix("bolero_bassline") == true && musician.status.spotlightColor != .red {
                                return false
                            } else if musician.sound?.infos.assetName.hasPrefix("bolero_accompaniement") == true && musician.status.spotlightColor != .green {
                                return false
                            }
                        }
                        
                        return true
                    }, stepAction: {
                        SpotlightModel.shared.disactivateAllSpotlights()
                        SpotlightModel.shared.setSpotlightActiveStatus(ofType: .goForwardArrow, to: true)
                        SpotlightModel.shared.setSpotlightActiveStatus(ofType: .allSpotlightChanges, to: true)
                    }),
                    LevelModel.TextStep(text: "Congratulations you did it all right!!! You can now explore the song in its entirety. When you want to quit, tap on the door icon like in the tutorial, have fun!", stepAction: {
                        SpotlightModel.shared.disactivateAllSpotlights()
                        SpotlightModel.shared.setSpotlightActiveStatus(ofType: .door, to: true)
                        TopTrailingActionsView.Model.shared.unlockedLevel = .twoThemes
                    })
                ]), MM: MM, PM: PM)
                NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM)
                    .frame(height: geometry.size.height * 0.8)
            }
            .overlay(alignment: .topTrailing, content: {
                TopTrailingActionsView()
            })
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

    
    private func createScene() -> SCNScene {
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/musicScene.scn")!
        
        let secondRootNote = SCNNode()
        
        scene.rootNode.addChildNode(secondRootNote)
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.name = "WWDC24-Camera"
        cameraNode.camera = SCNCamera()
        secondRootNote.addChildNode(cameraNode)
        
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
        secondRootNote.addChildNode(lightNode)
        
        let spotlightLightNode = SCNNode()
        spotlightLightNode.light = SCNLight()
        spotlightLightNode.light?.type = .spot
        spotlightLightNode.light?.intensity = 1000
        secondRootNote.addChildNode(spotlightLightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        secondRootNote.addChildNode(ambientLightNode)
                
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
        
        await createMusician(withSongName: "BoleroSounds/bolero_theme_clarinet.m4a", index: 0)
        await createMusician(withSongName: "BoleroSounds/bolero_bassline_drum.m4a", index: 1)
        await createMusician(withSongName: "BoleroSounds/bolero_theme_flute.m4a", index: 2)
        await createMusician(withSongName: "BoleroSounds/bolero_theme_oboe.m4a", index: 3)
        await createMusician(withSongName: "BoleroSounds/bolero_accompaniement_violin.m4a", index: 4)
        //await createMusician(withSongName: "BoleroSounds/bolerooboe.m4a", index: 5)
    }
}

#Preview {
    BoleroLevelTestView()
}

