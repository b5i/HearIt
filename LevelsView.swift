//
//  LevelsView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import SwiftUI

struct LevelsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    //@State private var selection: NavigationModel.Level = LevelsManager.shared.levelSelection
    
    @ObservedObject private var LM = LevelsManager.shared    
    var body: some View {
        // - TODO: Remove that log function when finished
        Self._printChanges()

        return GeometryReader { geometry in
            ZStack {
                // - TODO: Make a gradient: black/white background with moving centers that emit colors creating "random" shapes
                //Rectangle()
                //    .fill(.ellipticalGradient(colors: [.pink, .gray, .blue]))
                //    .ignoresSafeArea()
                         
                let selectionBinding: Binding<NavigationModel.Level> = Binding(get: {
                    return LM.levelSelection
                }, set: { newValue in
                    if !LM.isDoingTransition {
                        LM.levelSelection = newValue
                    }
                }) // - TODO: Try to avoid any scroll gesture when the model is doing a transition
                
                TabView(selection: selectionBinding) {
                    let levels = NavigationModel.Level.allCases
                    let lastLevelIndex = levels.count - 1
                    ForEach(Array(levels.enumerated()), id: \.offset) { (offset: Int, level: NavigationModel.Level) in
                        HStack {
                            if offset == 0 {
                                Spacer()
                                    .frame(width: geometry.size.width * 0.4)
                                    .opacity(LM.levelStarted ? 0 : 1)
                            } else {
                                ZStack(alignment: .leading) {
                                    Line()
                                        .stroke(style: .init(lineWidth: 10, lineCap: .round, dash: [30], dashPhase: 200))
                                        .fill(colorScheme.textColor)
                                        //.foregroundStyle(colorScheme.textColor)
                                        .frame(width: geometry.size.width * 0.4, height: 1)
                                    RoundedRectangle(cornerRadius: 20)
                                        .foregroundStyle(colorScheme.textColor)
                                        .frame(width: LM.unlockedLevels[levels[offset]] ?? 0 > 1 ? geometry.size.width * 0.40 : 0, height: 10.5)
                                        .offset(x: 5, y: -1) // fix little visual bug
                                }
                                .verticallyCentered()
                                .opacity(LM.levelStarted ? 0 : 1)
                            }
                            Button {
                                LevelsManager.shared.startLevel(level)
                            } label: {
                                Text("Start")
                                    .scaleEffect(LM.levelStarted ? 10 : 1)
                                    .foregroundStyle(colorScheme.textColor)
                            }
                            .opacity(LM.levelStarted ? 0 : 8)
                            .frame(width: geometry.size.width * 0.2)
                            
                            if offset == lastLevelIndex {
                                Spacer()
                                    .frame(width: geometry.size.width * 0.4)
                                    .opacity(LM.levelStarted ? 0 : 1)
                            } else {
                                ZStack(alignment: .leading) {
                                    Line()
                                        .stroke(style: .init(lineWidth: 10, lineCap: .round, dash: [30], dashPhase: 200))
                                        .fill(colorScheme.textColor)
                                        .frame(width: geometry.size.width * 0.4, height: 1)
                                    RoundedRectangle(cornerRadius: 20)
                                        .foregroundStyle(colorScheme.textColor)
                                        .frame(width: LM.unlockedLevels[levels[offset + 1]] ?? 0 > 0 ? geometry.size.width * 0.4 : 0, height: 10.5)
                                        .offset(x: -5, y: -1) // fix little visual bug
                                }
                                .verticallyCentered()
                                .opacity(LM.levelStarted ? 0 : 1)
                            }
                        }
                        .overlay(alignment: .top, content: {
                            Text(level.rawValue)
                                .font(.system(size: 80))
                                .bold()
                                .opacity(LM.levelStarted ? 0 : 1)
                        })
                        .tag(level)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
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
                })/*
                .castedOnChange(of: LM.levelSelection, perform: {
                    withAnimation {
                        self.selection = LM.levelSelection
                    }
                })*/
            }
        }
    }
}

#Preview {
    LevelsView()
}

extension View {
    func castedOnChange<V>(of value: V, perform action: @escaping () -> Void) -> some View where V: Equatable {
        if #available(iOS 17.0, *) {
            print(value)
            return self.onChange(of: value, {
                action()
            })
        } else {
            print(value)
            return self.onChange(of: value, perform: {_ in
                action()
            })
        }
    }
}

