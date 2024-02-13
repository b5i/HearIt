//
//  TwoThemesTestView.swift
//  
//
//  Created by Antoine Bollengier on 11.02.2024.
//

import SwiftUI
import PHASE
import SceneKit

struct TwoThemesTestView: View {
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
                        LevelModel.TextStep(text: "Here is the 20th concerto from Mozart, it's a bit easier than the 25th. Let's see if you understood the theory correctly."),
                        LevelModel.TextStep(text: "Your goal is to locate more or less precisely (I'll be indulgent) where Theme A start, where it ends and so where the bridge starts in addition to the beginning of the Theme B that is also the end of the bridge."),
                        LevelModel.ViewStep(view: {
                            VStack {
                                Text("You have access to two buttons, when you think that the song's part changes (i.e Theme A started, bridge started or Theme B started), click on the checkmark button. If you want to reset your last click you can click on the clockwise arrow. The bar will be colored with your selection. Click on the usual arrow to confirm your choice.") // TODO: Find a better explanation and add the possiblity to manually change the selection
                                HStack {
                                    Button {
                                        var newConfig = PM.currentSongPartsConfiguration
                                        
                                        if let newStartTime = PM.sounds.values.first?.timeObserver.currentTime, let minusIndex = newConfig?.songParts.firstIndex(where: {$0.startTime == -1}) {
                                            newConfig?.songParts[minusIndex].startTime = newStartTime
                                        }
                                        
                                        PM.changeConfiguration(for: newConfig)
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .frame(width: 40, height: 40)
                                    //.disabled(PM.currentSongPartsConfiguration?.songParts.contains(where: {$0.startTime == -1}) == false)
                                    //.id(PM.currentSongPartsConfiguration?.uuid)

                                    Button {
                                        var newConfig = PM.currentSongPartsConfiguration
                                        
                                        if let minusIndex = newConfig?.songParts.firstIndex(where: {$0.startTime != -1 && $0.startTime != 0}) {
                                            newConfig?.songParts[minusIndex].startTime = -1
                                        }
                                        
                                        PM.changeConfiguration(for: newConfig)
                                    } label: {
                                        Image(systemName: "arrow.clockwise")
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .frame(width: 40, height: 40)
                                    //.disabled(PM.currentSongPartsConfiguration?.songParts.contains(where: {$0.startTime != -1 && $0.startTime != 0 /* the first one is always 0*/ }) == false)
                                    //.id(PM.currentSongPartsConfiguration?.uuid)

                                }
                            }
                        }), // TODO: disable the continue button if there still -1 parts
                        LevelModel.TextStep(text: "Congratulations you did it all right!!! You can now explore the song in its entirety. When you want to quit, tap on the door icon like in the tutorial, have fun!", stepAction: {
                            //TopTrailingActionsView.Model.shared.unlockedLevel = .twoThemes
                        })
                    ]), MM: MM, PM: PM)
                    NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM)
                        .frame(height: geometry.size.height * 0.8) // TODO: precise here which soundObserver to use
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
        
        await createMusician(withSongName: "ThemesSounds/mozart20celloandbass.m4a", index: 0)
        await createMusician(withSongName: "ThemesSounds/mozart20flutesandoboe.m4a", index: 1)
        await createMusician(withSongName: "ThemesSounds/mozart20piano.m4a", index: 2)
        await createMusician(withSongName: "ThemesSounds/mozart20viola.m4a", index: 3)
        await createMusician(withSongName: "ThemesSounds/mozart20violins.m4a", index: 4)
        
        PM.changeConfiguration(for: .init(songParts: [
            .init(startTime: 0, type: .introduction, label: "Introduction"),
            .init(startTime: -1, type: .themeA, label: "Theme A"),
            .init(startTime: -1, type: .bridge, label: "Bridge"),
            .init(startTime: -1, type: .themeB, label: "Theme B")
        ]))
    }
}

#Preview {
    TwoThemesTestView()
}

