//
//  TutorialLevelView.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 04.02.2024.
//

import SwiftUI
import PHASE
import SceneKit

struct TutorialLevelView: View {
    @StateObject private var PM = PlaybackManager()
    
    @Binding var isLoadingScene: Bool
    @State private var isSceneLoaded: Bool = false
    @State private var scene: SCNScene?
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
        
    var body: some View {
        if isLoadingScene {
            Color.clear.frame(width: 0, height: 0)
        } else if let scene = scene, let MM = MM {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer()
                    NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM, soundToObserveName: "tutorialkick2")
                        .frame(height: geometry.size.height * 0.8)
                }
                .overlay(alignment: .topLeading, content: {
                    SceneStepsView(levelModel: LevelModel(steps: [
                        LevelModel.TextStep(text: "Welcome to \(appName), to begin I'll teach you the basic controls that you have over the app: \nTo go to the next instruction, click on the circled arrow at your right. \nIf you're unable to locate it, perform a long press on the light bulb icon at the top right corner of the screen, this will highlight the button you need to click."),
                        LevelModel.TextStep(text: "Let's start with the basics playback controls of the app. To begin playing music, click on the rectangular button next to the playing bar or press space if you have a keyboard connected to your device.", passCondition: { mm, pm in
                            return pm.sounds.first?.value.timeObserver.isPlaying ?? false // - TODO: maybe set true as default value
                        }, stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .playPause, to: true)
                        }),
                        LevelModel.TextStep(text: "Great! You can now hear a kick, to move forward or backward within the track, move the orange cursor to the time you want to listen to. If you move slowly, the bar will expand and let you select the precise second you want to listen to.", stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .playbackCapsule, to: true)
                        }),
                        LevelModel.TextStep(text: "Let's move on to the controls that you have over the musicians, you can mute and unmute a musician by clicking on the speaker icon under them or directly by clicking on the musician itself. Mute the musician to go to the next step.", passCondition: { mm, pm in
                            let sound = MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialkick2"})?.value.musician.sound
                            return sound?.isMuted ?? false
                        }, stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .mute(assetName: "tutorialkick2"), to: true)
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.sound?.mute()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.hide()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.sound?.mute()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.hide()
                            
                            MM.placeCameraToDefaultPosition()
                        }),
                        LevelModel.TextStep(text: "If you have multiple musicians, you can decide to mute all of them except one, this operation is called the solo operation. To solo a musician, tap on the \"S\" button next to the mute/unmute one. Unmute and solo the first musician to continue.", passCondition: { mm, pm in
                            let sound = MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialkick2"})?.value.musician.sound
                            return !(sound?.isMuted ?? false) && (sound?.isSoloed ?? false)
                        }, stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .solo(assetName: "tutorialkick2"), to: true)
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .mute(assetName: "tutorialkick2"), to: true)
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.sound?.unmute()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.show()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.sound?.unmute()
                            
                            MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.show()
                            
                            MM.recenterCamera()
                        }),
                        LevelModel.TextStep(text: "You can also set a loop to the song using the button at the right of the playing bar. If there's a yellow line above the playback bar, it indicates that there's a loop on the song. If the pencil next to the button is not crossed out, you can modify the length of the loop by dragging one of its sides to the left or right. To keep the length of the loop and just move it, you can drag the middle of the top yellow line.", passCondition: { _,_ in return true}, stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = nil
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .loopActivation, to: true)
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .loopEditability, to: true)
                            PM.replaceLoop(by: .init(startTime: 0, endTime: 20, shouldRestart: false, lockLoopZone: true, isEditable: true))
                        }),
                        LevelModel.TextStep(text: "If the small lock next to the loop activation button is open, it means that if you seek to a moment after the end of the loop, the loop will disappear. But if the lock is closed then you won't be able to seek any further than the end of the loop. If the pencil is not crossed, it means that you can also modify this behavior by clicking on the lock.", passCondition: { _,_ in return true}, stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = nil
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .loopLock, to: true)
                        }),
                        LevelModel.TextStep(text: "In the upcoming levels, you'll be asked to change the color of the musician, it actually refers to the color of the spotlight in front of them. To change its color, click on the spotlight or on the small square between the mute and solo buttons. Clicking multiple times will switch between blue, green and red. Set the color of the first musician's spotlight to red to proceed.", passCondition: { mm, _ in
                            return MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialkick2"})?.value.musician.status.spotlightColor == .red
                        }, stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = nil
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .spotlightChange(assetName: "tutorialkick2"), to: true)
                        }),
                        LevelModel.TextStep(text: "Congratulations! You've finished the tutorial phase and you now know everything about the controls of the app. To quit this tutorial, click on the open door at the top right next to the light bulb button.", stepAction: {
                            TopTrailingActionsView.Model.shared.unlockedLevel = .boleroTheme
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .door, to: true)
                        })
                    ]), MM: MM, PM: PM)
                    .onAppear {
                        SpotlightModel.shared.disactivateAllSpotlights()
                        SpotlightModel.shared.setSpotlightActiveStatus(ofType: .goForwardArrow, to: true, placeInQueue: true)
                    }
                })
            }
            .overlay(alignment: .topTrailing, content: {
                TopTrailingActionsView()
            })
            /*
            .overlay(alignment: .trailing) {
                Text("Texture")
                    .foregroundStyle(.white)
                    .onTapGesture {
                        MM.musicians.first(where: {$0.value.musician.sound!.infos.assetName == "tutorialkick2"})!.value.musician.setIntrumentTextureTo(.piano)
                    }
            }
            .overlay(alignment: .trailing) {
                HStack {
                    Button("x+") {
                        MM.musicians.first?.value.musician.spotlightNode.light?.areaExtents.x += 0.1
                    }
                    Button("x-") {
                        MM.musicians.first?.value.musician.spotlightNode.light?.areaExtents.x -= 0.1
                    }
                    Button("y+") {
                        MM.musicians.first?.value.musician.spotlightNode.light?.areaExtents.y += 0.1
                    }
                    Button("y-") {
                        MM.musicians.first?.value.musician.spotlightNode.light?.areaExtents.y -= 0.1
                    }
                    Button("z+") {
                        MM.musicians.first?.value.musician.spotlightNode.light?.areaExtents.z += 0.1
                    }
                    Button("z-") {
                        MM.musicians.first?.value.musician.spotlightNode.light?.areaExtents.z -= 0.1
                    }
                }
            }
             */
        } else {
            Color.clear
                .onAppear {
                    if self.scene == nil && !self.isLoadingScene {
                        self.isLoadingScene = true
                        let scene = SCNScene.createDefaultScene()
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
    
    private func setupTutorial(MM: MusiciansManager) async {
                
        await MM.createMusician(withSongName: "TutorialSounds/tutorialkick2.m4a", index: 0, PM: PM, name: "Kick", instrument: .drums)
        await MM.createMusician(withSongName: "TutorialSounds/tutorialhihat2.m4a", index: 1, PM: PM, name: "Hi-Hat", instrument: .maracas)
        await MM.createMusician(withSongName: "TutorialSounds/tutorialsnare2.m4a", index: 2, PM: PM, name: "Snare", instrument: .drums)
        
        MM.musicians.values.forEach({$0.musician.sound?.timeObserver.durationMultiplier = 4})
        
        MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.sound?.mute()
        
        MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialhihat2"})?.value.musician.hide()
        
        MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.sound?.mute()
        
        MM.musicians.first(where: {$0.value.musician.sound?.infos.assetName == "tutorialsnare2"})?.value.musician.hide()
        
        MM.placeCameraToDefaultPosition()
        
        await PM.reloadEngine()
    }
}
