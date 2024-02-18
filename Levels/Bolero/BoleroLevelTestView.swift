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
    
    @ObservedObject private var AM = AnswersModel.shared
    
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
                            AM.hideButton()
                        }),
                        LevelModel.ViewStep(view: {
                            VStack {
                                Text("Your objective is to identify which musician is performing each element. Multiple musicians can play the same element simultaneously. To submit your choice, adjust the color of the musician corresponding to what you believe they are playing, as explained in the tutorial. Once you've completed your selections, click the right arrow to confirm your results. Best of luck!")
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
                                        Text("Accompaniment")
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
                            AM.showButton(answersView: BoleroAnswers())
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .goForwardArrow, to: true)
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .allSpotlightChanges, to: true)
                        }),
                        LevelModel.TextStep(text: "Congratulations you did it all right!!! You can now explore the song in its entirety. When you want to quit, tap on the door icon like in the tutorial, have fun!", stepAction: {
                            AM.hideButton()
                            SpotlightModel.shared.disactivateAllSpotlights()
                            SpotlightModel.shared.setSpotlightActiveStatus(ofType: .door, to: true)
                            TopTrailingActionsView.Model.shared.unlockedLevel = .twoThemes
                        })
                    ]), MM: MM, PM: PM)
                    .padding(.top, 40)
                    .padding(.leading, 40)
                    NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM)
                        .frame(height: geometry.size.height * 0.85)
                }
                .overlay(alignment: .topTrailing, content: {
                    TopTrailingActionsView()
                })
                .answersOverlay()
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
        await MM.createMusician(withSongName: "BoleroSounds/bolero_theme_clarinet.m4a", index: 0, PM: PM, name: "Clarinet")
        await MM.createMusician(withSongName: "BoleroSounds/bolero_bassline_snare.m4a", index: 1, PM: PM, name: "Drum Snare")
        await MM.createMusician(withSongName: "BoleroSounds/bolero_theme_flute.m4a", index: 2, PM: PM, name: "Flute")
        await MM.createMusician(withSongName: "BoleroSounds/bolero_theme_oboe.m4a", index: 3, PM: PM, name: "Oboe")
        await MM.createMusician(withSongName: "BoleroSounds/bolero_accompaniment_violins2.m4a", index: 4, PM: PM, name: "Violins")
        
        MM.recenterCamera()
        
        await PM.reloadEngine()
    }
}

struct BoleroAnswers: LevelAnswers {
    var view: some View {
        HStack {
            Spacer()
            let answers: [Color] = [.blue, .red, .blue, .blue, .green]
            ForEach(Array(answers.enumerated()), id: \.offset) { offset, color in
                VStack(alignment: .center) {
                    Text("Musician nº \(offset + 1)")
                        .foregroundStyle(.white)
                    SingleAnswerView(color: color)
                }
                    .frame(width: 110)
                Spacer()
            }
        }
    }
    
    struct SingleAnswerView: View {
        let color: Color
        
        @State private var showAnswer: Bool = false
        var body: some View {
            if showAnswer {
                VStack {
                    /*
                    Image(systemName: "figure.wave.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(color)
                     */
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(color)
                        .frame(width: 60, height: 60)
                    
                    var role: String {
                        switch color {
                        case .blue:
                            return "Theme"
                        case .green:
                            return "Accompaniment"
                        case .red:
                            return "Bassline"
                        default:
                            return ""
                        }
                    }
                    Text(role)
                        .font(.caption)
                    //Text(color == .blue ? "Theme" : color == .green ? "Accompaniment" : color == .red ? "Bassline" : "")
                }
            } else {
                VStack {
                    Image(systemName: "eye.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                    Text("See answer")
                        .foregroundStyle(.white)
                }
                .onTapGesture {
                    withAnimation {
                        self.showAnswer = true
                    }
                }
            }
        }
    }
}
