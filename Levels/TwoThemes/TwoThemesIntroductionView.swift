//
//  TwoThemesIntroductionView.swift
//
//
//  Created by Antoine Bollengier on 11.02.2024.
//

import SwiftUI
import PHASE
import SceneKit

struct TwoThemesIntroductionView: View {
    @StateObject private var PM = PlaybackManager()
        
    @State private var isLoadingScene: Bool = false
    @State private var isSceneLoaded: Bool = false
    @State private var scene: SCNScene?
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
    
    @Binding var finishedIntroduction: Bool
        
    var body: some View {
        if isLoadingScene {
            ProgressView()
        } else if let scene = scene, let MM = MM {
            GeometryReader { geometry in
            VStack {
                SceneStepsView(levelModel: LevelModel(steps: [
                    LevelModel.TextStep(text: "Welcome! In this level you will learn about themes in music. A theme is, as you've seen in level \"\(LevelsManager.Level.boleroTheme.rawValue)\" the main melody in a song. It can be played by multiple intruments, together or in solo. A lot of music doesn't contain only one theme but several. They are usually called Theme A and Theme B and so on. To distinguish them each other, compositors usually put a bridge or a little pause between them."),
                    LevelModel.TextStep(text: "You've probably already heard a musician saying that he/she made a \"variation\" around a theme. What he/she actually means is that they created a song using some elements of the theme or even all of it, and then created a new accompaniment and bassline for it."),
                    LevelModel.TextStep(text: "Let me show you an example with the 25th symphony from Mozart. I starts with the Theme A played by the violins and the viola.", stepAction: {
                        for sound in PM.sounds.values {
                            sound.unsolo()
                            sound.unmute()
                        }
                        PM.seekTo(time: 5.6 /* beginning of the Theme A */)
                        PM.resume()
                    }),
                    LevelModel.TextStep(text: "Then a bridge follows, it is characterized by the tension it brings and by the fact that it prepares, for example by introducing new instruments, to the next theme. In this bridge (all actually) no complex melody is played in th and all the instruments act as accompaniment and the bass (but its not present here) ???? à verifier avec Raph.", stepAction: {
                        // reset states
                        for sound in PM.sounds.values {
                            sound.unsolo()
                            sound.unmute()
                        }
                        PM.seekTo(time: 22.5 /* beginning of the bridge */)
                    }),
                    LevelModel.TextStep(text: "Then Theme B starts, themes usually start by priority order. You'll generally remember the Theme A of a song better than Theme B, (another difference is that the first themes are generally more played than the other ones.", stepAction: {
                        // reset states
                        for sound in PM.sounds.values {
                            sound.unsolo()
                            sound.unmute()
                        }
                        PM.seekTo(time: 52.2 /* beginning of the Theme B */)
                    }),
                    LevelModel.TextStep(text: "Click on the right arrow when you're ready to take the test."),
                    LevelModel.TextStep(text: "", stepAction: {
                        withAnimation {
                            self.finishedIntroduction = true
                        }
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
                
        await createMusician(withSongName: "ThemesSounds/mozart25cellandbass.m4a", index: 0, color: .green)
        await createMusician(withSongName: "ThemesSounds/mozart25horns.m4a", index: 1, color: .green)
        await createMusician(withSongName: "ThemesSounds/mozart25oboe.m4a", index: 2, color: .red)
        await createMusician(withSongName: "ThemesSounds/mozart25violas.m4a", index: 3, color: .red)
        await createMusician(withSongName: "ThemesSounds/mozart25violins.m4a", index: 4, color: .red)
    }
}

