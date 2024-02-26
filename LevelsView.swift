//
//  LevelsView.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import SwiftUI

struct LevelsView: View {
    static let isLevelScrollEnabled: Bool = true
    
    @Environment(\.colorScheme) private var colorScheme
    
    //@State private var selection: NavigationModel.Level = LevelsManager.shared.levelSelection
    let homeScreenAnimation: Namespace.ID
    
    let shouldGradientGoToMiddle: Bool
    
    @State private var showCredits: Bool = false
    @ObservedObject private var LM = LevelsManager.shared
    @ObservedObject private var NM = NavigationModel.shared
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(.black)
                    .ignoresSafeArea()
                //Rectangle()
                //    .fill(.ellipticalGradient(colors: [.pink, .gray, .blue]))
                //    .ignoresSafeArea()
                         
                let selectionBinding: Binding<String> = Binding(get: {
                    return LM.levelSelection.rawValue
                }, set: { newValue in
                    guard !LM.isDoingTransition else { return }
                    if let level = NavigationModel.Level(rawValue: newValue) {
                        LM.levelSelection = level
                    } else {
                        withAnimation {
                            NavigationModel.shared.currentStep = .homeScreen
                        }
                    }
                }) // - TODO: Try to avoid any scroll gesture when the model is doing a transition
                
                TabView(selection: selectionBinding) {
                    /* to be activated
                    ZStack {
                        Rectangle()
                            .fill(colorScheme.backgroundColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea()
                            .matchedGeometryEffect(id: "HomeScreen", in: homeScreenAnimation)

                        HStack {
                            Image(systemName: "arrow.left")
                                .resizable()
                                .scaledToFit()
                                .bold()
                                .frame(width: geometry.size.width * 0.1)
                            VStack {
                                Image(systemName: "house.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .bold()
                                    .frame(width: geometry.size.width * 0.1)
                                Text("Home Menu")
                                    .font(.title)
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .padding()
                    }
                        .tag("HomeScreen")
                     */
                    
                    let levels = NavigationModel.Level.allCases
                    let lastLevelIndex = levels.count - 1
                    ForEach(Array(levels.filter({ (LM.unlockedLevels[$0] ?? 0) != 0 || $0 == .tutorial || Self.isLevelScrollEnabled}).enumerated()), id: \.offset) { (offset: Int, level: NavigationModel.Level) in
                        ZStack {
                            BackgroundGradientView(level: level, shouldGoToMiddle: shouldGradientGoToMiddle)
                            HStack {
                                if offset == 0 {
                                    Spacer()
                                        .frame(width: geometry.size.width * 0.4)
                                        .opacity(LM.levelStarted ? 0 : 1)
                                } else {
                                    ZStack(alignment: .leading) {
                                        Line()
                                            .stroke(style: .init(lineWidth: 10, lineCap: .round, dash: [30], dashPhase: 200))
                                            //.fill(colorScheme.textColor)
                                            .fill(.white.opacity(LM.levelStarted ? 0 : 1))
                                        //.foregroundStyle(colorScheme.textColor)
                                            .frame(width: geometry.size.width * 0.4, height: 1)
                                            .animation(.smooth(duration: 0.2), value: LM.levelStarted)
                                            .overlay(alignment: .leading, content: {
                                                RoundedRectangle(cornerRadius: 20)
                                                    //.foregroundStyle(colorScheme.textColor)
                                                    .foregroundStyle(.white)
                                                    .frame(width: LM.unlockedLevels[levels[offset]] ?? 0 > 1 ? geometry.size.width * 0.4 + 20 : 0, height: 10.5)
                                                    .offset(x: -5 - 10, y: -1) // fix little visual bug
                                                    .opacity(LM.levelStarted ? 0 : 1)
                                                    .animation(.smooth(duration: 0.2), value: LM.levelStarted)
                                            })
                                    }
                                    .verticallyCentered()
                                    .opacity(LM.levelStarted ? 0 : 1)
                                    .animation(.smooth(duration: 0.2), value: LM.levelStarted)
                                }
                                StartButton(mode: .black) {
                                    LevelsManager.shared.startLevel(level)
                                }
                                .padding()
                                .opacity(LM.levelStarted ? 0 : 1)
                                .animation(.smooth(duration: 0.2), value: LM.levelStarted)
                                
                                /*
                                Button {
                                    LevelsManager.shared.startLevel(level)
                                } label: {
                                    Text("Start")
                                        //.foregroundStyle(colorScheme.textColor)
                                        .foregroundStyle(.white)
                                }
                                .opacity(LM.levelStarted ? 0 : 1)
                                .frame(width: geometry.size.width * 0.2)
                                */
                                if offset == lastLevelIndex {
                                    Spacer()
                                        .frame(width: geometry.size.width * 0.4)
                                        .opacity(LM.levelStarted ? 0 : 1)
                                } else {
                                    ZStack(alignment: .leading) {
                                        Line()
                                            .stroke(style: .init(lineWidth: 10, lineCap: .round, dash: [30], dashPhase: 200))
                                            //.fill(colorScheme.textColor)
                                            .fill(.white.opacity(LM.levelStarted ? 0 : 1))
                                            .frame(width: geometry.size.width * 0.4, height: 1)
                                            .animation(.smooth(duration: 0.2), value: LM.levelStarted)
                                            .overlay(alignment: .leading, content: {
                                                RoundedRectangle(cornerRadius: 20)
                                                    //.foregroundStyle(colorScheme.textColor)
                                                    .foregroundStyle(.white)
                                                    .frame(width: LM.unlockedLevels[levels[offset + 1]] ?? 0 > 0 ? geometry.size.width * 0.4 + 20 : 0, height: 10.5)
                                                    .offset(x: 5 - 10, y: -1) // fix little visual bug
                                                    .opacity(LM.levelStarted ? 0 : 1)
                                                    .animation(.smooth(duration: 0.2), value: LM.levelStarted)
                                            })
                                    }
                                    .verticallyCentered()
                                    .opacity(LM.levelStarted ? 0 : 1)
                                    .animation(.smooth(duration: 0.2), value: LM.levelStarted)
                                }
                            }
                            .overlay(alignment: .top, content: {
                                Text(level.rawValue)
                                    .font(.system(size: 80))
                                    .bold()
                                    .foregroundStyle(.white)
                                    .opacity(LM.levelStarted ? 0 : 1)
                            })
                        }
                        .tag(level.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .overlay(alignment: .bottomTrailing, content: {
                    Image(systemName: "book")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.yellow)
                        .padding()
                        .padding()
                        .offset(x: LM.levelStarted ? 100 : 0)
                        .opacity(LM.levelStarted ? 0 : 1)
                        .animation(.spring(duration: 0.5), value: LM.levelStarted)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                self.showCredits = true
                            }
                        }
                })
                /*
                .overlay(alignment: .bottom, content: {
                    HStack {
                        Button("Home") {
                            NavigationModel.shared.currentStep = .homeScreen
                        }
                        Button("Reset") {
                            LM.reset()
                        }
                        Button("Unlock tutorial") {
                            LM.unlockLevel(.boleroTheme)
                        }
                        Button("Unlock sec") {
                            LM.unlockLevel(.twoThemes)
                        }
                    }
                    .opacity(LM.levelStarted ? 0 : 1)
                })*//*
                .castedOnChange(of: LM.levelSelection, perform: {
                    withAnimation {
                        self.selection = LM.levelSelection
                    }
                })*/
            }
            .creditsOverlay(isActive: $showCredits)
        }
        .ignoresSafeArea()
    }
}

fileprivate extension View {
    func homeScreenButtonAnimation(isActive: Bool, namespace: Namespace.ID) -> some View {
        if isActive {
            return AnyView(self.matchedGeometryEffect(id: "StartButton", in: namespace))
        } else {
            return AnyView(self)
        }
    }
}
