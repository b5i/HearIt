//
//  LevelsManager.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

class LevelsManager: ObservableObject {
    typealias Level = NavigationModel.Level
    
    static let shared = LevelsManager()
    
    @Published var levelSelection: Level = .tutorial
    
    @Published private(set) var levelStarted: Bool = false
    
    @Published private(set) var unlockedLevels: [NavigationModel.Level: Int] = [:] 
    
    @Published private(set) var isDoingTransition: Bool = false
    
    func startLevel(_ level: Level) {
        guard !isDoingTransition else { return }
        
        self.isDoingTransition = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 /* so we're sure that the transition will be finished */, execute: {
                self.isDoingTransition = false
            })
            withAnimation(.spring(duration: 0.2)) {
                NavigationModel.shared.currentStep = .levelView(level: level)
            }
        })
        withAnimation(.easeInOut(duration: 0.6)) {
            self.levelStarted = true
        }
    }
    
    func unlockLevel(_ level: Level) {
        guard !isDoingTransition else { return }
        
        self.isDoingTransition = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.isDoingTransition = false
            })
            
            withAnimation(.spring(duration: 0.4)) {
                self.levelSelection = level
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.spring(duration: 0.4)) {
                self.unlockedLevels[level] = 2
            }
        }
        withAnimation(.spring(duration: 0.4)) {
            self.unlockedLevels[level] = 1
        }
    }
    
    func returnToLevelsView(unlockingLevel level: Level?) {
        NotificationCenter.default.post(name: .shouldStopEveryEngineNotification, object: nil)
        AnswersModel.shared.hideButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if let level = level {
                LevelsManager.shared.unlockLevel(level)
                TopTrailingActionsView.Model.shared.unlockedLevel = nil
            }
        })
        
        withAnimation(.easeOut(duration: 0.5)) {
            NavigationModel.shared.currentStep = .levelsView
            self.levelStarted = false
        }
    }
    
    func reset() {
        self.isDoingTransition = false
        withAnimation {
            self.unlockedLevels = [:]
        }
    }
}
