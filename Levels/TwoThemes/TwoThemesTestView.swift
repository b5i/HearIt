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
                    Spacer()
                    NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM, disabledFeatures: isLevelFinished ? .changeSpotlightColorFeature : 0)
                        .frame(height: geometry.size.height * 0.78) // TODO: precise here which soundObserver to use
                }
                .overlay(alignment: .topLeading, content: {
                    SceneStepsView(levelModel: LevelModel(steps: [
                        LevelModel.TextStep(text: "Here is the 25th symphony from Mozart, it's a bit easier than the 20th concerto that you've heard before. Let's see if you understood the theory correctly."),
                        LevelModel.TextStep(text: "Your task is to locate more or less precisely (I'll be indulgent) where Theme A, the bridge, Theme B and the CODA (conclusion) start.", stepAction: {
                            SpotlightModel.shared.disactivateAllSpotlights()
                            AnswersModel.shared.hideButton()
                        }),
                        LevelModel.ViewStep(view: {
                            VStack {
                                Text("You now have control over two new buttons. When you discern a change in the song's section (i.e. Theme A, the bridge, Theme B or the CODA started), press the checkmark button. If you wish to undo your previous selection, simply click the clockwise arrow. Your selections will be visually represented by the colored playing bar. Finally, click the standard right arrow to confirm your choice.")
                                    .foregroundStyle(.white)
                                HStack {
                                    Button {
                                        var newConfig = PM.currentSongPartsConfiguration
                                        
                                        if let newStartTime = PM.sounds.values.first?.timeObserver.currentTime, let minusIndex = newConfig?.songParts.firstIndex(where: {$0.startTime == -1}) {
                                            if let partThatBeginsAfterCurrentTime /* lol */ = newConfig?.songParts.last(where: {$0.startTime > newStartTime})?.startTime { // prevent the user to have a part that begins before another if it's not intended
                                                newConfig?.songParts[minusIndex].startTime = min(partThatBeginsAfterCurrentTime + 1, PM.sounds.values.first?.timeObserver.soundDuration ?? partThatBeginsAfterCurrentTime + 1)
                                            } else {
                                                newConfig?.songParts[minusIndex].startTime = newStartTime
                                            }
                                        }
                                        
                                        PM.changeConfiguration(for: newConfig)
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .frame(width: 40, height: 40)
                                    .padding(.horizontal)
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
                                    .padding(.horizontal)
                                    .spotlight(type: .removeLastPart, areaRadius: 40)
                                    //.disabled(PM.currentSongPartsConfiguration?.songParts.contains(where: {$0.startTime != -1 && $0.startTime != 0 /* the first one is always 0*/ }) == false)
                                    //.id(PM.currentSongPartsConfiguration?.uuid)

                                }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .onAppear {
                                SpotlightModel.shared.disactivateAllSpotlights()
                                SpotlightModel.shared.setSpotlightActiveStatus(ofType: .addPart, to: true, placeInQueue: true)
                                SpotlightModel.shared.setSpotlightActiveStatus(ofType: .removeLastPart, to: true, placeInQueue: true)
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
                        }, stepAction: {
                            AnswersModel.shared.showButton(answersView: TwoThemesAnswers(answers: .init(songParts: [
                                .init(startTime: 0.0, type: .introduction, label: "Introduction"),
                                .init(startTime: 5.6, type: .themeA, label: "Theme A"),
                                .init(startTime: 17, type: .bridge, label: "Bridge"),
                                .init(startTime: 39, type: .themeB, label: "Theme B"),
                                .init(startTime: 68.5, type: .ending, label: "CODA")
                            ]), totalDuration: PM.sounds.first?.value.timeObserver.soundDuration ?? 100)) // TODO: remove that 100 ting
                        }), // TODO: disable the continue button if there still -1 parts
                        LevelModel.TextStep(text: "Congratulations you did it all right!!! You can now explore the song in its entirety. When you want to quit, tap on the door icon like in the tutorial, have fun!", stepAction: {
                            AnswersModel.shared.hideButton()
                            self.isLevelFinished = true
                            SpotlightModel.shared.disactivateAllSpotlights()
                            PM.changeConfiguration(for: .init(songParts: [
                                .init(startTime: 0.0, type: .introduction, label: "Introduction"),
                                .init(startTime: 5.6, type: .themeA, label: "Theme A"),
                                .init(startTime: 17, type: .bridge, label: "Bridge"),
                                .init(startTime: 39, type: .themeB, label: "Theme B"),
                                .init(startTime: 68, type: .ending, label: "CODA")
                            ]))
                        })
                    ]), MM: MM, PM: PM)
                    .frame(alignment: .top)
                })
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
        await MM.createMusician(withSongName: "ThemesSounds/mozart25celloandbass.m4a", index: 0, PM: PM, name: "Cello & Contrabass", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [] /* always playing */, colors: self.isLevelFinished ? [(25.4, .green), (44.4, .red), (52.9, .blue), (68, .red), (sound.timeObserver.soundDuration, .green)] : []) // raph
        }, instrument: .chords)
        await MM.createMusician(withSongName: "ThemesSounds/mozart25horns.m4a", index: 1, PM: PM, name: "French Horns", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [0.0, 6.3], colors: self.isLevelFinished ? [(55.7, .green), (68, .red) ,(sound.timeObserver.soundDuration, .green)] : [])
        }, instrument: .trumpet)
        await MM.createMusician(withSongName: "ThemesSounds/mozart25oboe.m4a", index: 2, PM: PM, name: "Oboe", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [], colors: self.isLevelFinished ? [(6, .green), (17, .blue), (68, .green) ,(sound.timeObserver.soundDuration, .green)] : [])
        }, instrument: .flute)
        await MM.createMusician(withSongName: "ThemesSounds/mozart25violas.m4a", index: 3, PM: PM, name: "Violas", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [], colors: self.isLevelFinished ? [(6, .red), (17, .blue), (68, .red) ,(sound.timeObserver.soundDuration, .green)] : [])
        }, instrument: .chords)
        await MM.createMusician(withSongName: "ThemesSounds/mozart25violins.m4a", audioLevel: 5, index: 4, PM: PM, name: "Violins", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [], colors: self.isLevelFinished ? [(6, .red), (17, .blue), (24.7, .red), (39, .green), (68, .blue), (sound.timeObserver.soundDuration, .green)] : [])
        }, instrument: .chords)
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

struct TwoThemesAnswers: LevelAnswers {
    let answers: PlaybackManager.SongPartsConfiguration
    let totalDuration: Double
    
    @State private var revealedParts: [PlaybackManager.SongPartsConfiguration.Part] = []

    var view: some View {
        MainAnswersView(answers: answers, totalDuration: totalDuration)
    }
    
    struct MainAnswersView: View {
        let answers: PlaybackManager.SongPartsConfiguration
        let totalDuration: Double
        @State private var revealedParts: [PlaybackManager.SongPartsConfiguration.Part] = []
        
        var body: some View {
            VStack {
                HStack {
                    Spacer()
                    ForEach(Array(answers.songParts.enumerated()), id: \.offset) { offset, answer in
                        SingleAnswerView(answer: answer, revealedParts: $revealedParts)
                            .frame(width: 150)
                        Spacer()
                    }
                }
                let answersCount = answers.songParts.count
                var stops: [(percentage: Double, color: Color, label: String)] {
                    var toReturn: [(percentage: Double, color: Color, label: String)] = []
                    for (offset, part) in answers.songParts.enumerated() {
                        if offset == answersCount - 1 {
                            toReturn.append(((totalDuration - part.startTime) / totalDuration, revealedParts.first(where: { $0 == part })?.getColor() ?? Color(uiColor: .darkGray), part.label))
                        } else {
                            toReturn.append(((answers.songParts[offset + 1].startTime - part.startTime) / totalDuration, revealedParts.first(where: { $0 == part })?.getColor() ?? Color(uiColor: .darkGray), part.label))
                        }
                    }
                    
                    return toReturn
                }
                
                PlayingBarView.SegmentedRectangleView(stops: stops)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(height: 20)
                    .padding()
                    .padding()
            }
        }
    }
    
    struct SingleAnswerView: View {
        let answer: PlaybackManager.SongPartsConfiguration.Part
        
        @Binding var revealedParts: [PlaybackManager.SongPartsConfiguration.Part]
        
        @State private var showAnswer: Bool = false
        var body: some View {
            HStack(alignment: .center, spacing: 0) {
                Text("\(answer.label) begins at \(showAnswer ? answer.startTime.timestampFormatted() : "")")
                    .foregroundStyle(.white)
                if !showAnswer {
                    Image(systemName: "eye.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            withAnimation {
                                self.showAnswer = true
                                self.revealedParts.append(answer)
                            }
                        }
                }
            }
        }
    }
}
