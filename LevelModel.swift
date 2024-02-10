//
//  LevelModel.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

class LevelModel: ObservableObject {
    struct Step {
        var text: String
        var passCondition: (MusiciansManager, PlaybackManager) -> Bool = {_,_  in return true}
        
        /// An action that will be called whenever the step appears. Could be used to set the spotlight position for example.
        var stepAction: (() -> Void)?
    }
    
    init(steps: [Step]) {
        self.steps = steps
    }
    
    @Published private var steps: [Step]
    
    @Published private var currentStepIndex: Int = 0
    
    var currentStep: Step? {
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
            }
        }
    }
    
    func goToNextStep(musicianManager: MusiciansManager, playbackManager: PlaybackManager) {
        if self.steps[self.currentStepIndex].passCondition(musicianManager, playbackManager) {
            if self.steps.count > self.currentStepIndex + 1 {
                withAnimation {
                    self.currentStepIndex += 1
                }
            } else {
                withAnimation {
                    self.currentStepIndex = -1
                }
            }
        }
    }
}
