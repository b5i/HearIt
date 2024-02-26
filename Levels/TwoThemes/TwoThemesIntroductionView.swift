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
        
    @Binding var isLoadingScene: Bool
    @State private var isSceneLoaded: Bool = false
    @State private var scene: SCNScene?
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
    
    @Binding var finishedIntroduction: Bool
        
    var body: some View {
        if isLoadingScene {
            Color.clear.frame(width: 0, height: 0)
        } else if let scene = scene, let MM = MM {
            GeometryReader { geometry in
            VStack {
                Spacer()
                NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM, disabledFeatures: .changeSpotlightColorFeature)
                    .frame(height: geometry.size.height * 0.8)
            }
            .overlay(alignment: .topLeading, content: {
                SceneStepsView(levelModel: LevelModel(steps: [
                    LevelModel.TextStep(text: "Welcome! In this level you will learn about themes in music. A theme, as you've seen in level \"\(LevelsManager.Level.boleroTheme.rawValue)\", is the main melody in a song. It can be played by multiple intruments, either together or as solos. A lot of music doesn't contain only one theme, but several. They are usually called Theme A and Theme B and so on. To separate them from each other, compositors usually put a bridge (a moment with no melody, just the accompaniment and maybe a bassline) and/or a brief pause between them."),
                    LevelModel.TextStep(text: "You may have heard a musician saying that he/she made a \"variation\" on a theme. What he/she actually means is that they created a song using some elements of the theme or even all of it, and then created a new accompaniment and bassline for it.", stepAction: {
                        if !(PM.currentLoop?.isEditable ?? true) { // remove the loop only if it has been set up by the game and not by the player
                            PM.removeLoop()
                        }
                    }),
                    LevelModel.TextStep(text: "Let me show you an example with Mozart's 20th Piano Concerto. I starts with the introduction, it usually directly precede the Theme A. The introduction can be very short or very long depending on the song.", stepAction: {
                        for sound in PM.sounds.values {
                            sound.unsolo()
                            sound.unmute()
                        }
                        
                        guard let introduction = PM.currentSongPartsConfiguration?.songParts.first(where: {$0.type == .introduction}), let themeA = PM.currentSongPartsConfiguration?.songParts.first(where: {$0.type == .themeA}) else { return }
                        
                        PM.replaceLoop(by: .init(startTime: introduction.startTime, endTime: themeA.startTime, shouldRestart: true, lockLoopZone: true, isEditable: false))
                    }),
                    LevelModel.TextStep(text: "Then follows the Theme A, played by the violins. Notice how \"devilish\" this theme is made by the gliding of the accompaniment and the melody that's always out of sync.", stepAction: {
                        for sound in PM.sounds.values {
                            sound.unsolo()
                            sound.unmute()
                        }
                        
                        guard let themeA = PM.currentSongPartsConfiguration?.songParts.first(where: {$0.type == .themeA}), let bridge = PM.currentSongPartsConfiguration?.songParts.first(where: {$0.type == .bridge}) else { return }
                        
                        PM.replaceLoop(by: .init(startTime: themeA.startTime, endTime: bridge.startTime, shouldRestart: true, lockLoopZone: true, isEditable: false))
                    }),
                    LevelModel.TextStep(text: "Then a bridge follows, it is characterized by the tension it brings and by the fact that it prepares, for example by introducing new instruments, to the next theme. In bridges (including this one) no complex melody is played in and all the instruments act as accompaniment or bassline.", stepAction: {
                        // reset states
                        for sound in PM.sounds.values {
                            sound.unsolo()
                            sound.unmute()
                        }
                        
                        guard let bridge = PM.currentSongPartsConfiguration?.songParts.first(where: {$0.type == .bridge}), let themeB = PM.currentSongPartsConfiguration?.songParts.first(where: {$0.type == .themeB}) else { return }
                        
                        PM.replaceLoop(by: .init(startTime: bridge.startTime, endTime: themeB.startTime, shouldRestart: true, lockLoopZone: true, isEditable: false))
                    }),
                    LevelModel.TextStep(text: "Then Theme B starts. Themes usually start by priority order; you'll generally remember the Theme A of a song better than Theme B. Another difference is the change of atmosphere: remember when I said that theme A was kind of \"devilish\", here Theme B is the opposite: it starts peacefully with a sort of dialog between the piano and the woodwinds (the oboe and the flutes).", stepAction: {
                        SpotlightModel.shared.disactivateAllSpotlights()
                        // reset states
                        for sound in PM.sounds.values {
                            sound.unsolo()
                            sound.unmute()
                        }
                        
                        guard let themeB = PM.currentSongPartsConfiguration?.songParts.first(where: {$0.type == .themeB}), let coda = PM.currentSongPartsConfiguration?.songParts.first(where: {$0.type == .ending}) else { return }
                        
                        PM.replaceLoop(by: .init(startTime: themeB.startTime, endTime: coda.startTime, shouldRestart: true, lockLoopZone: true, isEditable: false))
                    }),
                    LevelModel.TextStep(text: "Finally, the CODA (the name of the end of a song in music) concludes the song.", stepAction: {
                        SpotlightModel.shared.disactivateAllSpotlights()
                        // reset states
                        for sound in PM.sounds.values {
                            sound.unsolo()
                            sound.unmute()
                        }
                        
                        guard let coda = PM.currentSongPartsConfiguration?.songParts.first(where: {$0.type == .ending}), let songDuration = PM.sounds.first?.value.timeObserver.soundDuration else { return }
                        
                        PM.replaceLoop(by: .init(startTime: coda.startTime, endTime: songDuration - 0.3 /* so it doesn't restart */, shouldRestart: true, lockLoopZone: true, isEditable: false))
                    }),
                    LevelModel.TextStep(text: "You now have time to observe the song and when you're ready to take the test, click on the right arrow.", stepAction: {
                        SpotlightModel.shared.disactivateAllSpotlights()
                        SpotlightModel.shared.setSpotlightActiveStatus(ofType: .goForwardArrow, to: true)
                        
                        if !(PM.currentLoop?.isEditable ?? true) { // remove the loop only if it has been set up by the game and not by the player
                            PM.removeLoop()
                        }
                    }),
                    LevelModel.TextStep(text: "", stepAction: {
                        SpotlightModel.shared.disactivateAllSpotlights()
                        NotificationCenter.default.post(name: .shouldStopEveryEngineNotification, object: nil)
                        SpotlightModel.shared.clearCache()
                        withAnimation {
                            self.finishedIntroduction = true
                        }
                    })
                ]), MM: MM, PM: PM)
            })
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
 
        await MM.createMusician(withSongName: "ThemesSounds/mozart20celloandbass.m4a", index: 0, PM: PM, color: .red, name: "Cello & Contrabass", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [0.0, 5.5, 37, 43.75, 48, 60.5], colors: [(31.8, .red), (sound.timeObserver.soundDuration, .green)])
        }, instrument: .chords)
        await MM.createMusician(withSongName: "ThemesSounds/mozart20flutesandoboe.m4a", index: 1, PM: PM, color: .blue, name: "Flutes & Oboe", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [5.5, 40.2, 60], colors: [(50, .green), (sound.timeObserver.soundDuration, .blue)])
        }, instrument: .flute)
        await MM.createMusician(withSongName: "ThemesSounds/mozart20piano.m4a", audioLevel: 4, index: 2, PM: PM, color: .blue, name: "Piano", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [5.5, 12.5, 44.5, 51.2], colors: [(37, .blue), (51.2, .green), (66, .blue), (sound.timeObserver.soundDuration, .green)])
        }, instrument: .piano)
        await MM.createMusician(withSongName: "ThemesSounds/mozart20viola.m4a", index: 3, PM: PM, color: .green, name: "Viola", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [37, 43.5, 48, 60.5], colors: [(sound.timeObserver.soundDuration, .green)])
        }, instrument: .chords)
        await MM.createMusician(withSongName: "ThemesSounds/mozart20violins.m4a", index: 4, PM: PM, color: .blue, name: "Violins", handler: { sound in
            Musician.handleTime(sound: sound, powerOnOff: [37, 43.5, 48, 51.2], colors: [(7.38, .green), (31.8, .blue), (43.5, .green), (sound.timeObserver.soundDuration, .green)])
        }, instrument: .chords)
        
        MM.recenterCamera()
        
        PM.changeConfiguration(for: .init(songParts: [
            .init(startTime: 0, type: .introduction, label: "Introduction"),
            .init(startTime: 5.5, type: .themeA, label: "Theme A"),
            .init(startTime: 37, type: .bridge, label: "Bridge"),
            .init(startTime: 49, type: .themeB, label: "Theme B"),
            .init(startTime: 66.5, type: .ending, label: "CODA (end)")
        ]))
        
        MM.recenterCamera()
        
        await PM.reloadEngine()
    }
}

