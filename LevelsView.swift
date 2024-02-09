//
//  LevelsView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import SwiftUI

struct LevelsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showContent: Bool = true
    @ObservedObject private var LM = LevelsManager.shared
    @State private var levelsSelection: NavigationModel.Level = .tutorial
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $levelsSelection) {
                HStack {
                    Spacer()
                        .frame(width: geometry.size.width * 0.4)
                        .opacity(showContent ? 1 : 0)
                    VStack {
                        LevelHeaderView(level: .tutorial, startLevelAction: {
                            self.showContent = false
                        })
                    }
                    .frame(width: geometry.size.width * 0.2)
                    ZStack(alignment: .leading) {
                        Line()
                            .stroke(style: .init(lineWidth: 10, lineCap: .round, dash: [30], dashPhase: 200))
                            .fill(colorScheme.textColor)
                            .frame(width: geometry.size.width * 0.4, height: 1)
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(colorScheme.textColor)
                            .frame(width: LM.tutorialUnlocked > 0 ? geometry.size.width * 0.4 : 0, height: 11)
                    }
                    .verticallyCentered()
                    .opacity(showContent ? 1 : 0)
                }
                .tag(NavigationModel.Level.tutorial)
                HStack {
                    ZStack(alignment: .leading) {
                        Line()
                            .stroke(style: .init(lineWidth: 10, lineCap: .round, dash: [30], dashPhase: 200))
                            .fill(colorScheme.textColor)
                            .frame(width: geometry.size.width * 0.4, height: 1)
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(colorScheme.textColor)
                            .frame(width: LM.tutorialUnlocked > 1 ? geometry.size.width * 0.4 : 0, height: 11)
                    }
                    .verticallyCentered()
                    .opacity(showContent ? 1 : 0)
                    LevelHeaderView(level: .boleroTheme, startLevelAction: {
                        self.showContent = false
                    })
                    .frame(width: geometry.size.width * 0.2)
                    ZStack(alignment: .leading) {
                        Line()
                            .stroke(style: .init(lineWidth: 10, lineCap: .round, dash: [30], dashPhase: 200))
                            .fill(colorScheme.textColor)
                            .frame(width: geometry.size.width * 0.4, height: 1)
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(colorScheme.textColor)
                            .frame(width: LM.boleroThemeUnlocked > 0 ? geometry.size.width * 0.4 : 0, height: 11)
                    }
                    .verticallyCentered()
                    .opacity(showContent ? 1 : 0)
                }
                .tag(NavigationModel.Level.boleroTheme)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .overlay(alignment: .bottom, content: {
                HStack {
                    Button("Reset") {
                        LM.tutorialUnlocked = 0
                        self.levelsSelection = .tutorial
                    }
                    Button("Unlock tutorial") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.spring(duration: 0.4)) {
                                self.levelsSelection = .boleroTheme
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.spring(duration: 0.4)) {
                                LM.tutorialUnlocked = 2
                            }
                        }
                        withAnimation(.spring(duration: 0.4)) {
                            LM.tutorialUnlocked = 1
                        }
                    }
                }
                .opacity(showContent ? 1 : 0)
            })
        }
    }
    
    struct LevelHeaderView: View {
        @Environment(\.colorScheme) private var colorScheme
        
        let level: NavigationModel.Level
        let startLevelAction: () -> ()
        
        @State private var levelStarted: Bool = false
        
        var body: some View {
            VStack {
                Text(level.rawValue)
                    .opacity(levelStarted ? 0 : 1)
                    .foregroundStyle(colorScheme.textColor)
                Button {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                        withAnimation {
                            NavigationModel.shared.currentStep = .levelView(level: .tutorial)
                        }
                    })
                    withAnimation(.easeInOut(duration: 0.6)) {
                        self.levelStarted = true
                        self.startLevelAction()
                    }
                } label: {
                    Text("Start")
                        .scaleEffect(levelStarted ? 10 : 1)
                        .foregroundStyle(colorScheme.textColor)
                }
                .opacity(levelStarted ? 0 : 8)
            }
        }
    }
}

#Preview {
    LevelsView()
}

class LevelsManager: ObservableObject {
    static let shared = LevelsManager()
    
    @Published var tutorialUnlocked: Int = 0
    @Published var boleroThemeUnlocked: Int = 0
}
