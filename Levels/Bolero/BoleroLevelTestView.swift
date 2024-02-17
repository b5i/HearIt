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
                            } else if musician.sound?.infos.assetName.hasPrefix("bolero_accompaniment") == true && musician.status.spotlightColor != .green {
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
        await MM.createMusician(withSongName: "BoleroSounds/bolero_theme_clarinet.m4a", index: 0, PM: PM)
        await MM.createMusician(withSongName: "BoleroSounds/bolero_bassline_snare.m4a", index: 1, PM: PM)
        await MM.createMusician(withSongName: "BoleroSounds/bolero_theme_flute.m4a", index: 2, PM: PM)
        await MM.createMusician(withSongName: "BoleroSounds/bolero_theme_oboe.m4a", index: 3, PM: PM)
        await MM.createMusician(withSongName: "BoleroSounds/bolero_accompaniment_violins2.m4a", index: 4, PM: PM)
        
        MM.recenterCamera()
        
        await PM.reloadEngine()
    }
}

