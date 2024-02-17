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
    private let threshold: Double = 5.0
    
    @StateObject private var PM = PlaybackManager()
        
    @Binding var isLoadingScene: Bool
    @State private var isSceneLoaded: Bool = false
    @State private var scene: SCNScene?
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
    
    @State private var isLevelFinished: Bool = false
            
    var body: some View {
        if isLoadingScene {
            Color.clear.frame(width: 0, height: 0)
        } else if let scene = scene, let MM = MM {
            GeometryReader { geometry in
                VStack {
                    SceneStepsView(levelModel: LevelModel(steps: [
                        LevelModel.TextStep(text: "Here is the 25th symphony from Mozart, it's a bit easier than the 25th. Let's see if you understood the theory correctly."),
                        LevelModel.TextStep(text: "Your goal is to locate more or less precisely (I'll be indulgent) where Theme A start, where it ends and so where the bridge starts in addition to the beginning of the Theme B that is also the end of the bridge.", stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                        }),
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
                                    .spotlight(type: .addPart, areaRadius: 40)
                                    //.disabled(PM.currentSongPartsConfiguration?.songParts.contains(where: {$0.startTime == -1}) == false)
                                    //.id(PM.currentSongPartsConfiguration?.uuid)

                                    Button {
                                        var newConfig = PM.currentSongPartsConfiguration
                                        
                                        if let minusIndex = newConfig?.songParts.lastIndex(where: {$0.startTime != -1 && $0.startTime != 0}) {
                                            newConfig?.songParts[minusIndex].startTime = -1
                                        }
                                        
                                        PM.changeConfiguration(for: newConfig)
                                    } label: {
                                        Image(systemName: "arrow.clockwise")
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .frame(width: 40, height: 40)
                                    .spotlight(type: .removeLastPart, areaRadius: 40)
                                    //.disabled(PM.currentSongPartsConfiguration?.songParts.contains(where: {$0.startTime != -1 && $0.startTime != 0 /* the first one is always 0*/ }) == false)
                                    //.id(PM.currentSongPartsConfiguration?.uuid)

                                }
                            }
                            .onAppear {
                                SpotlightModel.shared.disactivateAllSpotlights()
                                SpotlightModel.shared.setSpotlightActiveStatus(ofType: .addPart, to: true)
                                SpotlightModel.shared.setSpotlightActiveStatus(ofType: .removeLastPart, to: true)
                            }
                        }, passCondition: { _, pm in
                            if let config = pm.currentSongPartsConfiguration {
                                for part in config.songParts {
                                    switch part.type {
                                    case .themeA:
                                        if abs(part.startTime - 5.6 /*actual startTime*/) > self.threshold {
                                            return false
                                        }
                                    case .themeB:
                                        if abs(part.startTime - 39.52 /*actual startTime*/) > self.threshold {
                                            return false
                                        }
                                    case .introduction:
                                        if abs(part.startTime - 0.0 /*actual startTime*/) > self.threshold {
                                            return false
                                        }
                                    case .ending:
                                        if abs(part.startTime - 68.5 /*actual startTime*/) > self.threshold {
                                            return false
                                        }
                                    case .bridge:
                                        if abs(part.startTime - 17 /*actual startTime*/) > self.threshold {
                                            return false
                                        }
                                    default:
                                        break
                                    }
                                }
                                
                                return true
                            } else {
                                return true
                            }
                        }), // TODO: disable the continue button if there still -1 parts
                        LevelModel.TextStep(text: "Congratulations you did it all right!!! You can now explore the song in its entirety. When you want to quit, tap on the door icon like in the tutorial, have fun!", stepAction: {
                            self.isLevelFinished = true
                            SpotlightModel.shared.disactivateAllSpotlights()
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
        await MM.createMusician(withSongName: "ThemesSounds/mozart25celloandbass.m4a", index: 0, PM: PM, color: .green, handler: { sound in
            guard self.isLevelFinished else { return }
            Musician.handleTime(sound: sound, powerOnOff: [] /* always playing */, colors: [(25.4, .green), (44.4, .red), (52.9, .blue), (70.5, .red), (sound.timeObserver.soundDuration, .blue)]) // raph
        })
        await MM.createMusician(withSongName: "ThemesSounds/mozart25horns.m4a", index: 1, PM: PM, color: .green, handler: { sound in
            guard self.isLevelFinished else { return }
            Musician.handleTime(sound: sound, powerOnOff: [0.0, 6.3], colors: [(55.7, .green), (70.5, .red) ,(sound.timeObserver.soundDuration, .blue)])
        })
        await MM.createMusician(withSongName: "ThemesSounds/mozart25oboe.m4a", index: 2, PM: PM, color: .green, handler: { sound in
            guard self.isLevelFinished else { return }
            Musician.handleTime(sound: sound, powerOnOff: [], colors: [(7, .green), (18.7, .blue), (70.5, .green) ,(sound.timeObserver.soundDuration, .blue)])
        })
        await MM.createMusician(withSongName: "ThemesSounds/mozart25violas.m4a", index: 3, PM: PM, color: .red, handler: { sound in
            guard self.isLevelFinished else { return }
            Musician.handleTime(sound: sound, powerOnOff: [], colors: [(7, .red), (18.7, .blue), (70.5, .red) ,(sound.timeObserver.soundDuration, .blue)])
        })
        await MM.createMusician(withSongName: "ThemesSounds/mozart25violins.m4a", index: 4, PM: PM, color: .red, handler: { sound in
            guard self.isLevelFinished else { return }
            Musician.handleTime(sound: sound, powerOnOff: [], colors: [(7, .red), (18.7, .blue), (24.7, .red), (41.6, .green), (sound.timeObserver.soundDuration, .blue)])
        })
        PM.changeConfiguration(for: .init(songParts: [
            .init(startTime: 0.0, type: .introduction, label: "Introduction"),
            .init(startTime: -1, type: .themeA, label: "Theme A"),
            .init(startTime: -1, type: .bridge, label: "Bridge"),
            .init(startTime: -1, type: .themeB, label: "Theme B"),
            .init(startTime: -1, type: .ending, label: "CODA")
        ]))
        
        MM.recenterCamera()
        
        await PM.reloadEngine()
    }
}

extension SpotlightModel.SpotlightType {
    static let addPart: SpotlightModel.SpotlightType = .custom(name: "addPart")
    
    static let removeLastPart: SpotlightModel.SpotlightType = .custom(name: "removeLastPart")
}

