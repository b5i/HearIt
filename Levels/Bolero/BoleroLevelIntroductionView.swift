//
//  BoleroLevelIntroductionView.swift
//
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI
import PHASE
import SceneKit

struct BoleroLevelIntroductionView: View {
    
    @StateObject private var PM = PlaybackManager()
        
    @State private var isLoadingScene: Bool = false
    @State private var isSceneLoaded: Bool = false
    @State private var scene: SCNScene?
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
    
    @Binding var finishedIntroduction: Bool
    
    @State private var disabledFeatures: DisabledFeatures = 0
        
    var body: some View {
        if isLoadingScene {
            ProgressView()
        } else if let scene = scene, let MM = MM {
            GeometryReader { geometry in
                VStack {
                    SceneStepsView(levelModel: LevelModel(steps: [
                        LevelModel.TextStep(text: "Welcome! In this level you will learn about themes/melodies, accompaniment and continuous bassline. Almost every music, from pop to classical, can be described as a composition of those 3 elements."),
                        LevelModel.TextStep(text: "Let me show you an example with this simple music that 4 musicians are playing.", stepAction: {
                            self.disabledFeatures = 0
                            for sound in PM.sounds.values {
                                sound.unsolo()
                                sound.unmute()
                            }
                            PM.restartAndSynchronizeSounds()
                        }),
                        LevelModel.TextStep(text: "The first thing you hear is definitely the riff of the guitar, it's called the theme or melody of the song. Note that it can be played by more than one instrument.", stepAction: {
                            self.disabledFeatures = .muteFeature | .soloFeature | .changeSpotlightColorFeature

                            // reset states
                            for (key, sound) in PM.sounds {
                                if key.hasPrefix("TutorialSounds/melody") {
                                    sound.solo()
                                } else {
                                    sound.unsolo()
                                }
                                sound.unmute()
                            }
                            PM.restartAndSynchronizeSounds()
                        }),
                        LevelModel.TextStep(text: "The second element is the accompaniment, here it is composed by a synthesizer and a some notes from a bass, it is here to provide a harmonic to the melody so it doesn't feel empty.", stepAction: {
                            // reset states
                            for (key, sound) in PM.sounds {
                                if key.hasPrefix("TutorialSounds/accompaniment") {
                                    sound.solo()
                                } else {
                                    sound.unsolo()
                                }
                                sound.unmute()
                            }
                            PM.restartAndSynchronizeSounds()
                        }),
                        LevelModel.TextStep(text: "And the final element is of course the continuous bassline, here it is represented by the little kick. The bassline gives the rythm to the music to support the theme. Note that the bassline can also be played by other instruments than drums/kick.", stepAction: {
                            self.disabledFeatures = .muteFeature | .soloFeature | .changeSpotlightColorFeature
                            // reset states
                            for (key, sound) in PM.sounds {
                                if key.hasPrefix("TutorialSounds/bassline") {
                                    sound.solo()
                                } else {
                                    sound.unsolo()
                                }
                                sound.unmute()
                            }
                            PM.restartAndSynchronizeSounds()
                        }),
                        LevelModel.TextStep(text: "Click on the right arrow when you're ready to take the test.", stepAction: {
                            self.disabledFeatures = 0
                        }),
                        LevelModel.TextStep(text: "", stepAction: {
                            withAnimation {
                                self.finishedIntroduction = true
                            }
                        })
                    ]), MM: MM, PM: PM)
                    NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM, disabledFeatures: disabledFeatures)
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
        func createMusician(withSongName songName: String, audioLevel: Double = 0, index: Int, color: Musician.SpotlightColor = .blue, handler: ((Sound) -> ())? = nil) async {
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
                    sound.infos.musician = newMusician
                    sound.infos.musiciansManager = MM
                    sound.infos.playbackManager = PM
                    sound.timeHandler = handler
                    newMusician.setSound(sound)
                    newMusician.soundDidChangePlaybackStatus(isPlaying: false)
                    newMusician.changeSpotlightColor(color: color)
                    sound.delegate = newMusician
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
        
        //await createMusician(withSongName: "TutorialSounds/la_panterra.mp3", audioLevel: -8, index: 0)
        
        
        await createMusician(withSongName: "TutorialSounds/melody.m4a", index: 0, color: .blue, handler: { sound in
            guard let musician = sound.infos.musician else { return }
            
            let currentTime = sound.timeObserver.currentTime
            
            if currentTime < 2, musician.status.spotlightColor != .blue {
                musician.changeSpotlightColor(color: .blue)
            } else if currentTime < 4, musician.status.spotlightColor != .red {
                musician.changeSpotlightColor(color: .red)
            } else if musician.status.spotlightColor != .green {
                musician.changeSpotlightColor(color: .green)
            }
        })
        await createMusician(withSongName: "TutorialSounds/accompaniment1.m4a", index: 1, color: .green)
        await createMusician(withSongName: "TutorialSounds/accompaniment2.m4a", index: 2, color: .green)
        await createMusician(withSongName: "TutorialSounds/bassline.m4a", index: 3, color: .red)
        
         
       /*
        await createMusician(withSongName: "TutorialSounds/tutorial_drums.m4a", index: 0)
        await createMusician(withSongName: "TutorialSounds/tutorial_hihats.m4a", index: 1)
        await createMusician(withSongName: "TutorialSounds/tutorial_kick.m4a", index: 2)
        await createMusician(withSongName: "TutorialSounds/tutorial_synth.m4a", audioLevel: -3, index: 3)
         */
                
        //self.PM.restartAndSynchronizeSounds()
    }
}

enum SceneFeature: UInt8 {
    case mute = 1
    case solo = 2
    case changeSpotlightColor = 4
    case playAndPause = 8
    case seek = 16
    
    case all = 255
    
    static func getFeatures(for flag: UInt8) -> [SceneFeature] {
        var toReturn: [SceneFeature] = []
        
        if flag[0] { toReturn.append(.mute) }
        if flag[1] { toReturn.append(.solo) }
        if flag[2] { toReturn.append(.changeSpotlightColor) }
        if flag[3] { toReturn.append(.playAndPause) }
        if flag[4] { toReturn.append(.seek) }
        
        return toReturn
    }
}

extension UInt8 {
    static let muteFeature: UInt8 = 1
    static let soloFeature: UInt8 = 2
    static let changeSpotlightColorFeature: UInt8 = 4
    static let playAndPauseFeature: UInt8 = 8
    static let seekFeature: UInt8 = 16
}

extension UInt8 {
    func contains(feature: UInt8) -> Bool {
        return self[feature]
    }
    
    public subscript(index: UInt8) -> Bool {
        return (self & index != 0)
    }
}
