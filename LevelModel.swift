//
//  LevelModel.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

protocol LevelStep {
    associatedtype Label: View
    var view: Label { get }
    
    var passCondition: (MusiciansManager, PlaybackManager) -> Bool { get }
    
    var stepAction: (() -> Void)? { get }
}

class LevelModel: ObservableObject {
    struct TextStep: LevelStep {
        var view: some View {
            Text(text)
        }
        
        var text: String
        
        var passCondition: (MusiciansManager, PlaybackManager) -> Bool = {_,_  in return true}
        
        /// An action that will be called whenever the step appears. Could be used to set the spotlight position for example.
        var stepAction: (() -> Void)?
        
        init(text: String, passCondition: @escaping (MusiciansManager, PlaybackManager) -> Bool = {_,_  in return true}, stepAction: (() -> Void)? = nil) {
            self.text = text
            self.passCondition = passCondition
            self.stepAction = stepAction
        }
    }
    
    struct ViewStep<Content: View>: LevelStep {
        var view: Content
                
        var passCondition: (MusiciansManager, PlaybackManager) -> Bool = {_,_  in return true}
        
        /// An action that will be called whenever the step appears. Could be used to set the spotlight position for example.
        var stepAction: (() -> Void)?
        
        init(@ViewBuilder view: () -> Content, passCondition: @escaping (MusiciansManager, PlaybackManager) -> Bool = {_,_  in return true}, stepAction: (() -> Void)? = nil) {
            self.view = view()
            self.passCondition = passCondition
            self.stepAction = stepAction
        }
    }
    
    init(steps: [TextStep]) {
        self.steps = steps
    }
    
    @Published private var steps: [TextStep]
    
    @Published private var currentStepIndex: Int = 0
    
    var currentStep: TextStep? {
        if self.steps.count > self.currentStepIndex && self.currentStepIndex != -1 {
            return self.steps[currentStepIndex]
        } else {
            return nil
        }
    }
    
    var previousStepExists: Bool {
        return self.currentStepIndex != 0 && !self.steps.isEmpty
    }
    
    var nextStepExists: Bool {
        return self.currentStepIndex != steps.count - 1 && !self.steps.isEmpty
    }
    
    func goToPreviousStep() {
        if self.currentStepIndex != 0 {
            withAnimation {
                self.currentStepIndex -= 1
                self.currentStep?.stepAction?()
            }
        }
    }
    
    func goToNextStep(musicianManager: MusiciansManager, playbackManager: PlaybackManager) {
        if self.steps[self.currentStepIndex].passCondition(musicianManager, playbackManager) {
            if self.steps.count > self.currentStepIndex + 1 {
                withAnimation {
                    self.currentStepIndex += 1
                    self.currentStep?.stepAction?()
                }
            } else {
                withAnimation {
                    self.currentStepIndex = -1
                }
            }
        }
    }
}
