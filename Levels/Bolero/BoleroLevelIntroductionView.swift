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
    static private var basslinePath = "BoleroSounds/tutorial_bassline.m4a"
    static private var melodyPath = "BoleroSounds/tutorial_melody2.m4a"
    static private var accompaniment1Path = "BoleroSounds/tutorial_accompaniment1.m4a"
    static private var accompaniment2Path = "BoleroSounds/tutorial_accompaniment2.m4a"
    
    @StateObject private var PM = PlaybackManager()
        
    @Binding var isLoadingScene: Bool
    @State private var isSceneLoaded: Bool = false
    @State private var scene: SCNScene?
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
    
    @Binding var finishedIntroduction: Bool
    
    @State private var disabledFeatures: DisabledFeatures = 0
        
    var body: some View {
        if isLoadingScene {
            Color.clear.frame(width: 0, height: 0)
        } else if let scene = scene, let MM = MM {
            GeometryReader { geometry in
                VStack {
                    SceneStepsView(levelModel: LevelModel(steps: [
                        LevelModel.TextStep(text: "Welcome! In this level you will learn about themes/melodies, accompaniment and continuous bassline. Almost every music, from pop to classical, can be characterized as compositions consisting of these three elements."),
                        LevelModel.TextStep(text: "Let me show you an example with this simple music that 4 musicians are playing.", stepAction: {
                            self.disabledFeatures = .changeSpotlightColorFeature
                            for sound in PM.sounds.values {
                                sound.unsolo()
                                sound.unmute()
                            }
                            PM.restartAndSynchronizeSounds()
                        }),
                        LevelModel.TextStep(text: "The first thing you hear is definitely the lead played by a synthesizers////, it's called the theme or melody of the song. Be aware that it can be played by more than one instrument.", stepAction: {
                            self.disabledFeatures = .muteFeature | .soloFeature | .changeSpotlightColorFeature

                            // reset states
                            for (key, sound) in PM.sounds {
                                if key == Self.melodyPath {
                                    sound.solo()
                                } else {
                                    sound.unsolo()
                                }
                                sound.unmute()
                            }
                            PM.restartAndSynchronizeSounds()
                        }),
                        LevelModel.TextStep(text: "The second element is the accompaniment, here it is composed by two other synthesizers, it is here to provide a harmonic to the melody so it doesn't feel empty.", stepAction: {
                            // reset states
                            for (key, sound) in PM.sounds {
                                if key == Self.accompaniment1Path || key == Self.accompaniment2Path {
                                    sound.solo()
                                } else {
                                    sound.unsolo()
                                }
                                sound.unmute()
                            }
                            PM.restartAndSynchronizeSounds()
                        }),
                        LevelModel.TextStep(text: "And the final element is of course the continuous bassline, here it is represented by the little kick. The bassline gives the rythm to the music and support the theme. Note that the bassline can also be played by other instruments than drums/kicks.", stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            self.disabledFeatures = .muteFeature | .soloFeature | .changeSpotlightColorFeature
                            // reset states
                            for (key, sound) in PM.sounds {
                                if key == Self.basslinePath {
                                    sound.solo()
                                } else {
                                    sound.unsolo()
                                }
                                sound.unmute()
                            }
                            PM.restartAndSynchronizeSounds()
                        }),
                        LevelModel.TextStep(text: "Click on the right arrow when you're ready to take the test.", stepAction: {
                            self.disabledFeatures = .changeSpotlightColorFeature
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .goForwardArrow, to: true)
                        }),
                        LevelModel.TextStep(text: "", stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            NotificationCenter.default.post(name: .shouldStopEveryEngineNotification, object: nil)
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
        
        await MM.createMusician(withSongName: Self.accompaniment1Path, index: 0, PM: PM, color: .green)
        await MM.createMusician(withSongName: Self.basslinePath, index: 1, PM: PM, color: .red)
        await MM.createMusician(withSongName: Self.melodyPath, index: 2, PM: PM, color: .blue)
        await MM.createMusician(withSongName: Self.accompaniment2Path, index: 3, PM: PM, color: .green)
        
        MM.recenterCamera()
        
        await PM.reloadEngine()
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
