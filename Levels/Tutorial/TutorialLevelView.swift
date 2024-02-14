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
                        LevelModel.TextStep(text: "Welcome in \(appName)! To begin I'll teach you the basic controls that you have over the app: \n To go to the next instruction, click on the circled arrow at your right. \n If you can't find it, do a long press on the light bulb at the top right, it will highlight the right button.", stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .lightBulb, to: true)
                        }),
                        LevelModel.TextStep(text: "Let's start with the basics playback controls of the app. For the music to start playing, click on the rectangular button next to the timeline and its orange cursor.", passCondition: { mm, pm in
                            return pm.sounds.first?.value.timeObserver.isPlaying ?? false // - TODO: maybe set true as default value
                        }, stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .playPause, to: true)
                        }),
                        LevelModel.TextStep(text: "Great! You can now hear a little melody, to move forward or backwards in it, move the orange cursor to the time you want to listen to. If you move slowly, the bar will become bigger and let you select the precise second that you want to listen to.", stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .playbackCapsule, to: true)
                        }),
                        LevelModel.TextStep(text: "Let's move on to the controls that you have over the musician, you can mute and unmute the musician by clicking on the speaker icon under the musician or directly by clicking on the musician. Mute him to go to the next step.", passCondition: { mm, pm in
                            let sound = MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialkick2"})?.value.musician.sound
                            return sound?.isMuted ?? false
                        }, stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .mute(assetName: "tutorialkick2"), to: true) // TODO: as there's multiple mute buttons, check if the spotlight is at the correct spot
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.sound?.mute()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.hide()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.sound?.mute()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.hide()
                        }),
                        LevelModel.TextStep(text: "If you have multiple musicians, you can decide to mute all of them except one, this operation is called the solo operation. To solo a musician, tap on the S button next to the mute/unmute one. Unmute and solo the first musician to continue.", passCondition: { mm, pm in
                            let sound = MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialkick2"})?.value.musician.sound
                            return !(sound?.isMuted ?? false) && (sound?.isSoloed ?? false)
                        }, stepAction: {
                            PM.replaceLoop(by: .init(startTime: 0, endTime: 58.5, shouldRestart: false, lockLoopZone: true, isEditable: false))
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .solo(assetName: "tutorialkick2"), to: true)
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .mute(assetName: "tutorialkick2"), to: true)
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.sound?.unmute()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.show()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.sound?.unmute()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.show()
                        }),
                        LevelModel.TextStep(text: "You perhaps already noticed it but there is a yellow line above the playing bar. It indicates that there's a loop on the song. If the pencil next to the button is not crossed out you can modify the length of the loop by dragging one of its side to the left or right. To keep the length of the loop and just move it you can drag the middle of the top yellow line.", passCondition: { _,_ in return true}, stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = nil
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .loopActivation, to: true)
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .loopEditability, to: true)
                            PM.replaceLoop(by: .init(startTime: 0, endTime: 58.5, shouldRestart: false, lockLoopZone: true, isEditable: true))
                        }),
                        LevelModel.TextStep(text: "If the little lock next to the loop activation button is open it means that if you seek to a moment after the end of the loop, the loop will disappear. But if the lock is closed then you won't be able to seek further than the end of the loop. If the pencil is not crossed, it means that you can also modify this behavior by clicking on the lock.", passCondition: { _,_ in return true}, stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = nil
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .loopLock, to: true)
                        }),
                        LevelModel.TextStep(text: "In the coming levels you'll be asked to change the color of the musician, it actually refers to the color of the spotlight in front of him. To change its color, click on the spotlight or on the little firgure that is raising its hand. Clicking multiple times on the musician will switch between blue, red and green. Set the color of the first musician's spotlight to green to proceed.", passCondition: { mm, _ in
                            return MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialkick2"})?.value.musician.status.spotlightColor == .green
                        }, stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = nil
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .spotlightChange(assetName: "tutorialkick2"), to: true)
                        }),
                        LevelModel.TextStep(text: "Congrats you finished the tutorial phase and you now know everything about the controls of the app. To quit this tutorial, click on the opened door at the top right next to the light bulb button.", stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = .boleroTheme
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .door, to: true)
                        })
                    ]), MM: MM, PM: PM)
                    NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM, soundToObserveName: "tutorialkick2")
                        .frame(height: geometry.size.height * 0.8)
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
                
        await createMusician(withSongName: "TutorialSounds/tutorialkick2.m4a", index: 0)
        await createMusician(withSongName: "TutorialSounds/tutorialhihat2.m4a", index: 1)
        await createMusician(withSongName: "TutorialSounds/tutorialsnare2.m4a", index: 2)
        
        MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialkick2"})?.value.musician.sound?.timeObserver.durationMultiplier = 4
        
        MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.sound?.mute()
        
        MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.hide()
        
        MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.sound?.mute()
        
        MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.hide()
        
        //let loopTime = (PM.sounds.values.map({$0.timeObserver.soundDuration}).min() ?? 3.6) + 0.1 /* approximated value of the duration, a bit more than the actual to that if the user scrolls to the end of the playing bar it won't get out of the loop */
                
        PM.replaceLoop(by: .init(startTime: 0, endTime: 58.5, shouldRestart: false, lockLoopZone: true, isEditable: false))
    }
}

#Preview {
    TutorialLevelView()
}
